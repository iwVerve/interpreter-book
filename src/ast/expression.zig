const std = @import("std");
const Allocator = std.mem.Allocator;

const ast = @import("../ast.zig");

const Config = @import("../Config.zig");
const Token = @import("../token.zig").Token;
const ExpressionParser = @import("../parser/expression.zig");
const Precedence = ExpressionParser.Precedence;
const getPrecedence = ExpressionParser.getPrecedence;

pub const Expression = union(enum) {
    binary: BinaryExpression,
    unary: UnaryExpression,
    if_: IfExpression,
    function: FunctionExpression,
    call: CallExpression,
    identifier: Identifier,
    builtin: Builtin,
    integer: Config.integer_type,
    string: []const u8,
    bool: bool,

    pub fn deinit(self: *Expression, allocator: Allocator) void {
        switch (self.*) {
            .binary => |*b| b.deinit(allocator),
            .unary => |*u| u.deinit(allocator),
            .if_ => |*i| i.deinit(allocator),
            .function => |*f| f.deinit(allocator),
            .call => |*c| c.deinit(allocator),
            .integer, .identifier, .builtin, .string, .bool => {},
        }
    }

    pub fn write(self: Expression, writer: anytype, precedence: Precedence) @TypeOf(writer).Error!void {
        switch (self) {
            .binary => |b| try b.write(writer, precedence),
            .unary => |u| try u.write(writer),
            .if_ => |i| try i.write(writer),
            .function => |f| try f.write(writer),
            .call => |c| try c.write(writer),
            .identifier => |i| try i.write(writer),
            .builtin => |b| try b.write(writer),
            .integer => |i| try writer.print("{}", .{i}),
            .string => |s| try writer.print("{s}", .{s}),
            .bool => |b| try writer.print("{}", .{b}),
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

pub const IfExpression = struct {
    condition: *Expression,
    then: *ast.Statement,
    else_: ?*ast.Statement,

    pub fn deinit(self: *IfExpression, allocator: Allocator) void {
        self.condition.deinit(allocator);
        allocator.destroy(self.condition);
        self.then.deinit(allocator);
        allocator.destroy(self.then);
        if (self.else_ != null) {
            self.else_.?.deinit(allocator);
            allocator.destroy(self.else_.?);
        }
    }

    pub fn write(self: IfExpression, writer: anytype) !void {
        try writer.print("if ", .{});
        try self.condition.write(writer, .lowest);
        try writer.print(" ", .{});
        try self.then.write(writer);
        if (self.else_ != null) {
            try writer.print("else ", .{});
            try self.else_.?.write(writer);
        }
    }
};

pub const FunctionExpression = struct {
    parameters: []const []const u8,
    body: *ast.Statement,

    pub fn deinit(self: *FunctionExpression, allocator: Allocator) void {
        allocator.free(self.parameters);
        self.body.deinit(allocator);
        allocator.destroy(self.body);
    }

    pub fn write(self: FunctionExpression, writer: anytype) !void {
        try writer.print("fn(", .{});
        var first = true;
        for (self.parameters) |parameter| {
            if (first) {
                first = false;
            } else {
                try writer.print(", ", .{});
            }
            try writer.print("{s}", .{parameter});
        }
        try writer.print(") ", .{});
        try self.body.write(writer);
    }
};

pub const CallExpression = struct {
    function: *Expression,
    arguments: []Expression,

    pub fn deinit(self: *CallExpression, allocator: Allocator) void {
        self.function.deinit(allocator);
        allocator.destroy(self.function);
        for (self.arguments) |*argument| {
            argument.deinit(allocator);
        }
        allocator.free(self.arguments);
    }

    pub fn write(self: CallExpression, writer: anytype) !void {
        try self.function.write(writer, .lowest);
        try writer.print("(", .{});
        var first = true;
        for (self.arguments) |argument| {
            if (first) {
                first = false;
            } else {
                try writer.print(", ", .{});
            }
            try argument.write(writer, .lowest);
        }
        try writer.print(")", .{});
    }
};

pub const Identifier = struct {
    name: []const u8,

    pub fn write(self: Identifier, writer: anytype) !void {
        try writer.print("{s}", .{self.name});
    }
};

pub const Builtin = struct {
    name: []const u8,

    pub fn write(self: Identifier, writer: anytype) !void {
        try writer.print("@{s}", .{self.name});
    }
};
