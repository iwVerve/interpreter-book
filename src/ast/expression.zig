const std = @import("std");
const Allocator = std.mem.Allocator;

const Config = @import("../Config.zig");

const Token = @import("../token.zig").Token;

const ExpressionWriteError = error{};

pub const Expression = union(enum) {
    binary: BinaryExpression,
    unary: UnaryExpression,
    identifier: Identifier,
    integer: Config.integer_type,

    pub fn deinit(self: *Expression, allocator: Allocator) void {
        switch (self.*) {
            .binary => |*b| b.deinit(allocator),
            .unary => |*u| u.deinit(allocator),
            .integer, .identifier => {},
        }
    }

    pub fn write(self: Expression, writer: anytype) @TypeOf(writer).Error!void {
        switch (self) {
            .binary => |b| try b.write(writer),
            .unary => |u| try u.write(writer),
            .identifier => |i| try i.write(writer),
            .integer => |i| try writer.print("{}", .{i}),
        }
    }
};

pub const BinaryExpression = struct {
    left: *Expression,
    operator: Token,
    right: *Expression,

    pub fn deinit(self: *BinaryExpression, allocator: Allocator) void {
        self.left.deinit(allocator);
        allocator.destroy(self.left);
        self.right.deinit(allocator);
        allocator.destroy(self.right);
    }

    pub fn write(self: BinaryExpression, writer: anytype) !void {
        try writer.print("(", .{});
        try self.left.write(writer);
        try writer.print(" ", .{});
        try self.operator.write(writer);
        try writer.print(" ", .{});
        try self.right.write(writer);
        try writer.print(")", .{});
    }
};

pub const UnaryExpression = struct {
    operator: Token,
    expression: *Expression,

    pub fn deinit(self: *UnaryExpression, allocator: Allocator) void {
        self.expression.deinit(allocator);
        allocator.destroy(self.expression);
    }

    pub fn write(self: UnaryExpression, writer: anytype) !void {
        try self.operator.write(writer);
        try self.expression.write(writer);
    }
};

pub const Identifier = struct {
    name: []const u8,

    pub fn write(self: Identifier, writer: anytype) !void {
        try writer.print("{s}", .{self.name});
    }
};
