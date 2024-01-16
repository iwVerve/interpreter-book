const std = @import("std");
const Token = @import("token.zig").Token;
const ArrayList = std.ArrayList;

pub const Statement = union(enum) {
    let: LetStatement,
    return_: ReturnStatement,
    if_: IfStatement,
    expression: Expression,
};

pub const LetStatement = struct {
    identifier: Identifier,
    expression: Expression,
};

pub const ReturnStatement = struct {
    expression: Expression,
};

pub const IfStatement = struct {
    condition: Expression,
    then: ArrayList(Statement),
    else_: ?ArrayList(Statement),
};

pub const Expression = union(enum) {
    integer_literal: IntegerLiteral,
    binary_expression: BinaryExpression,
    unary_expression: UnaryExpression,
    identifier: Identifier,
};

pub const BinaryExpression = struct {
    lvalue: *Expression,
    operator: Token,
    rvalue: *Expression,
};

pub const UnaryExpression = struct {
    operator: Token,
    value: *Expression,
};

pub const IntegerLiteral = struct {
    value: Token,
};

pub const Identifier = struct {
    name: Token,
};
