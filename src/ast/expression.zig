const std = @import("std");
const Allocator = std.mem.Allocator;

const Config = @import("../Config.zig");
const Token = @import("../token.zig").Token;
const ExpressionParser = @import("../parser/expression.zig");
const Precedence = ExpressionParser.Precedence;
const getPrecedence = ExpressionParser.getPrecedence;

pub const Expression = union(enum) {
    binary: BinaryExpression,
    unary: UnaryExpression,
    identifier: Identifier,
    integer: Config.integer_type,
    bool_: bool,

    pub fn deinit(self: *Expression, allocator: Allocator) void {
        switch (self.*) {
            .binary => |*b| b.deinit(allocator),
            .unary => |*u| u.deinit(allocator),
            .integer, .identifier, .bool_ => {},
        }
    }

    pub fn write(self: Expression, writer: anytype, precedence: Precedence) @TypeOf(writer).Error!void {
        switch (self) {
            .binary => |b| try b.write(writer, precedence),
            .unary => |u| try u.write(writer),
            .identifier => |i| try i.write(writer),
            .integer => |i| try writer.print("{}", .{i}),
            .bool_ => |b| try writer.print("{}", .{b}),
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

    pub fn write(self: BinaryExpression, writer: anytype, precedence: Precedence) !void {
        const my_precedence = getPrecedence(self.operator) orelse unreachable;
        const surround = @intFromEnum(my_precedence) < @intFromEnum(precedence);

        if (surround) {
            try writer.print("(", .{});
        }
        try self.left.write(writer, my_precedence);
        try writer.print(" ", .{});
        try self.operator.write(writer);
        try writer.print(" ", .{});
        try self.right.write(writer, my_precedence);
        if (surround) {
            try writer.print(")", .{});
        }
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
        try self.expression.write(writer, .prefix);
    }
};

pub const Identifier = struct {
    name: []const u8,

    pub fn write(self: Identifier, writer: anytype) !void {
        try writer.print("{s}", .{self.name});
    }
};
