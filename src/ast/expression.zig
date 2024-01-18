const std = @import("std");
const ArrayList = std.ArrayList;

const Token = @import("../token.zig").Token;
const Statement = @import("../ast.zig").Statement;

const SerializeOptions = @import("../serialize.zig").SerializeOptions;
const SerializeErrors = @import("../serialize.zig").SerializeErrors;

pub const Expression = union(enum) {
    integer_literal: IntegerLiteral,
    binary_expression: BinaryExpression,
    prefix_expression: PrefixExpression,
    identifier: Identifier,
    boolean_literal: BooleanLiteral,
    if_expression: IfExpression,
    function_literal: FunctionLiteral,
    call_expression: CallExpression,

    pub fn serialize(self: Expression, options: *SerializeOptions) SerializeErrors![]const u8 {
        return std.fmt.allocPrint(options.allocator, "{s}", .{try switch (self) {
            .integer_literal => self.integer_literal.serialize(options),
            .binary_expression => self.binary_expression.serialize(options),
            .prefix_expression => self.prefix_expression.serialize(options),
            .identifier => self.identifier.serialize(options),
            .boolean_literal => self.boolean_literal.serialize(options),
            .if_expression => self.if_expression.serialize(options),
            .function_literal => self.function_literal.serialize(options),
            .call_expression => self.call_expression.serialize(options),
        }});
    }
};

pub const BinaryExpression = struct {
    lvalue: *Expression,
    operator: Token,
    rvalue: *Expression,

    pub fn serialize(self: BinaryExpression, options: *SerializeOptions) SerializeErrors![]const u8 {
        return try std.fmt.allocPrint(options.allocator, "{s}{s}{s}", .{ try self.lvalue.serialize(options), try self.operator.serialize(options), try self.rvalue.serialize(options) });
    }
};

pub const PrefixExpression = struct {
    operator: Token,
    expression: *Expression,

    pub fn serialize(self: PrefixExpression, options: *SerializeOptions) SerializeErrors![]const u8 {
        return try std.fmt.allocPrint(options.allocator, "{s}{s}", .{ try self.operator.serialize(options), try self.expression.serialize(options) });
    }
};

pub const IntegerLiteral = struct {
    token: Token,
    value: i64,

    pub fn serialize(self: IntegerLiteral, options: *SerializeOptions) SerializeErrors![]const u8 {
        return try std.fmt.allocPrint(options.allocator, "{s}", .{try self.token.serialize(options)});
    }
};

pub const Identifier = struct {
    token: Token,
    name: []const u8,

    pub fn serialize(self: Identifier, options: *SerializeOptions) SerializeErrors![]const u8 {
        return try std.fmt.allocPrint(options.allocator, "{s}", .{try self.token.serialize(options)});
    }
};

pub const BooleanLiteral = struct {
    token: Token,
    value: bool,

    pub fn serialize(self: BooleanLiteral, options: *SerializeOptions) SerializeErrors![]const u8 {
        return try std.fmt.allocPrint(options.allocator, "{s}", .{try self.token.serialize(options)});
    }
};

pub const IfExpression = struct {
    condition: *Expression,
    then: *Statement,
    else_: ?*Statement,

    pub fn serialize(self: IfExpression, options: *SerializeOptions) SerializeErrors![]const u8 {
        return try std.fmt.allocPrint(options.allocator, "if {s} {s}", .{ try self.condition.serialize(options), try self.then.serialize(options) });
    }
};

pub const FunctionLiteral = struct {
    parameters: ArrayList(Identifier),
    body: *Statement,

    pub fn serialize(self: FunctionLiteral, options: *SerializeOptions) SerializeErrors![]const u8 {
        _ = self;
        return try std.fmt.allocPrint(options.allocator, "fn() {{...}}", .{});
    }
};

pub const CallExpression = struct {
    expression: *Expression,
    arguments: ArrayList(Expression),

    pub fn serialize(self: CallExpression, options: *SerializeOptions) SerializeErrors![]const u8 {
        return try std.fmt.allocPrint(options.allocator, "{s}(...)", .{try self.expression.serialize(options)});
    }
};
