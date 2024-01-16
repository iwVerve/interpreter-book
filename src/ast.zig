const std = @import("std");
const Token = @import("token.zig").Token;
const ArrayList = std.ArrayList;

pub const Statement = union(enum) {
    let: LetStatement,
    return_: ReturnStatement,
    if_: IfStatement,
    expression: Expression,

    pub fn format(value: Statement, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = fmt;
        switch (value) {
            .let => {
                try writer.print("{};", .{value.let});
            },
            .return_ => {
                try writer.print("{};", .{value.return_});
            },
            .if_ => {
                try writer.print("{};", .{value.if_});
            },
            .expression => {
                try writer.print("{};", .{value.expression});
            },
        }
    }
};

pub const LetStatement = struct {
    identifier: Identifier,
    expression: Expression,

    pub fn format(value: LetStatement, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = fmt;
        try writer.print("let {} = {}", .{ value.identifier, value.expression });
    }
};

pub const ReturnStatement = struct {
    expression: Expression,

    pub fn format(value: ReturnStatement, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = fmt;
        try writer.print("return {}", .{value.expression});
    }
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

    pub fn format(value: Expression, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = fmt;
        switch (value) {
            .integer_literal => {
                try writer.print("{}", .{value.integer_literal});
            },
            .binary_expression => {
                try writer.print("{}", .{value.binary_expression});
            },
            .unary_expression => {
                try writer.print("{}", .{value.unary_expression});
            },
            .identifier => {
                try writer.print("{}", .{value.identifier});
            },
        }
    }
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

    pub fn format(value: IntegerLiteral, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = fmt;
        try writer.print("{}", .{value.value});
    }
};

pub const Identifier = struct {
    name: Token,

    pub fn format(value: Identifier, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = fmt;
        try writer.print("{}", .{value.name});
    }
};
