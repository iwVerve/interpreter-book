const std = @import("std");
const ArrayList = std.ArrayList;

const Token = @import("../token.zig").Token;
const Statement = @import("../ast.zig").Statement;

const SerializeOptions = @import("serialize.zig").SerializeOptions;
const SerializeErrors = @import("serialize.zig").SerializeErrors;

const getPrecedence = @import("../parser/precedence.zig").getPrecedence;
const OperatorPrecedence = @import("../parser/precedence.zig").OperatorPrecedence;

pub const Expression = union(enum) {
    integer_literal: IntegerLiteral,
    binary_expression: BinaryExpression,
    prefix_expression: PrefixExpression,
    identifier: Identifier,
    boolean_literal: BooleanLiteral,
    if_expression: IfExpression,
    function_literal: FunctionLiteral,
    call_expression: CallExpression,

    pub fn write(self: Expression, writer: anytype, options: *SerializeOptions, precedence: OperatorPrecedence) SerializeErrors!void {
        switch (self) {
            .integer_literal => try self.integer_literal.write(writer, options),
            .binary_expression => try self.binary_expression.write(writer, options, precedence),
            .prefix_expression => try self.prefix_expression.write(writer, options),
            .identifier => try self.identifier.write(writer, options),
            .boolean_literal => try self.boolean_literal.write(writer, options),
            .if_expression => try self.if_expression.write(writer, options),
            .function_literal => try self.function_literal.write(writer, options),
            .call_expression => try self.call_expression.write(writer, options),
        }
    }
};

pub const BinaryExpression = struct {
    lvalue: *Expression,
    operator: Token,
    rvalue: *Expression,

    pub fn write(self: BinaryExpression, writer: anytype, options: *SerializeOptions, precedence: OperatorPrecedence) !void {
        const self_precedence = getPrecedence(self.operator) orelse .lowest;
        const surround = @intFromEnum(self_precedence) < @intFromEnum(precedence);

        if (surround) {
            _ = try writer.write("(");
        }
        try self.lvalue.write(writer, options, self_precedence);
        _ = try writer.write(" ");
        try self.operator.write(writer, options);
        _ = try writer.write(" ");
        try self.rvalue.write(writer, options, self_precedence);
        if (surround) {
            _ = try writer.write(")");
        }
    }
};

pub const PrefixExpression = struct {
    operator: Token,
    expression: *Expression,

    pub fn write(self: PrefixExpression, writer: anytype, options: *SerializeOptions) !void {
        try self.operator.write(writer, options);
        try self.expression.write(writer, options, .prefix);
    }
};

pub const IntegerLiteral = struct {
    token: Token,
    value: i64,

    pub fn write(self: IntegerLiteral, writer: anytype, options: *SerializeOptions) !void {
        try self.token.write(writer, options);
    }
};

pub const Identifier = struct {
    token: Token,
    name: []const u8,

    pub fn write(self: Identifier, writer: anytype, options: *SerializeOptions) !void {
        try self.token.write(writer, options);
    }
};

pub const BooleanLiteral = struct {
    token: Token,
    value: bool,

    pub fn write(self: BooleanLiteral, writer: anytype, options: *SerializeOptions) !void {
        try self.token.write(writer, options);
    }
};

pub const IfExpression = struct {
    condition: *Expression,
    then: *Statement,
    else_: ?*Statement,

    pub fn write(self: IfExpression, writer: anytype, options: *SerializeOptions) !void {
        _ = try writer.write("if ");
        try self.condition.write(writer, options, .lowest);
        _ = try writer.write(" ");
        try self.then.write(writer, options);
        if (self.else_) |else_some| {
            _ = try writer.write(" else ");
            try else_some.write(writer, options);
        }
    }
};

pub const FunctionLiteral = struct {
    parameters: ArrayList(Identifier),
    body: *Statement,

    pub fn write(self: FunctionLiteral, writer: anytype, options: *SerializeOptions) !void {
        _ = try writer.write("fn(");
        var first = true;
        for (self.parameters.items) |parameter| {
            if (first) {
                first = false;
            } else {
                _ = try writer.write(", ");
            }
            _ = try parameter.write(writer, options);
        }
        _ = try writer.write(") ");
        try self.body.write(writer, options);
    }
};

pub const CallExpression = struct {
    expression: *Expression,
    arguments: ArrayList(Expression),

    pub fn write(self: CallExpression, writer: anytype, options: *SerializeOptions) !void {
        try self.expression.write(writer, options, .lowest);
        _ = try writer.write("(");
        var first = true;
        for (self.arguments.items) |argument| {
            if (first) {
                first = false;
            } else {
                _ = try writer.write(", ");
            }
            try argument.write(writer, options, .lowest);
        }
        _ = try writer.write(")");
    }
};
