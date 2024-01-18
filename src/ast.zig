const std = @import("std");
const Token = @import("token.zig").Token;
const ArrayList = std.ArrayList;

pub const Statement = union(enum) {
    let: LetStatement,
    return_: ReturnStatement,
    expression: Expression,
    block: BlockStatement,

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
            .expression => {
                try writer.print("{};", .{value.expression});
            },
            .block => {
                try writer.print("{}", .{value.block});
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

pub const BlockStatement = struct {
    statements: ArrayList(Statement),

    pub fn format(value: BlockStatement, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = fmt;
        try writer.print("{{\n", .{});
        for (value.statements.items) |statement| {
            try writer.print("{}\n", .{statement});
        }
        try writer.print("}}", .{});
    }
};

pub const Expression = union(enum) {
    integer_literal: IntegerLiteral,
    binary_expression: BinaryExpression,
    prefix_expression: PrefixExpression,
    identifier: Identifier,
    boolean_literal: BooleanLiteral,
    if_expression: IfExpression,
    function_literal: FunctionLiteral,
    call_expression: CallExpression,

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
            .prefix_expression => {
                try writer.print("{}", .{value.prefix_expression});
            },
            .identifier => {
                try writer.print("{}", .{value.identifier});
            },
            .boolean_literal => {
                try writer.print("{}", .{value.boolean_literal});
            },
            .if_expression => {
                try writer.print("{}", .{value.if_expression});
            },
            .function_literal => {
                try writer.print("{}", .{value.function_literal});
            },
            .call_expression => {
                try writer.print("{}", .{value.call_expression});
            },
        }
    }
};

pub const BinaryExpression = struct {
    lvalue: *Expression,
    operator: Token,
    rvalue: *Expression,

    pub fn format(value: BinaryExpression, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = fmt;
        try writer.print("({} {} {})", .{ value.lvalue, value.operator, value.rvalue });
    }
};

pub const PrefixExpression = struct {
    operator: Token,
    expression: *Expression,

    pub fn format(value: PrefixExpression, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = fmt;
        try writer.print("{}{}", .{ value.operator, value.expression });
    }
};

pub const IntegerLiteral = struct {
    token: Token,
    value: i64,

    pub fn format(value: IntegerLiteral, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = fmt;
        try writer.print("{}", .{value.value});
    }
};

pub const Identifier = struct {
    token: Token,
    name: []const u8,

    pub fn format(value: Identifier, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = fmt;
        try writer.print("{s}", .{value.name});
    }
};

pub const BooleanLiteral = struct {
    token: Token,
    value: bool,

    pub fn format(value: BooleanLiteral, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = fmt;
        try writer.print("{}", .{value.value});
    }
};

pub const IfExpression = struct {
    condition: *Expression,
    then: *Statement,
    else_: ?*Statement,

    pub fn format(value: IfExpression, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = fmt;
        try writer.print("if {} {} else {?}", .{ value.condition, value.then, value.else_ });
    }
};

pub const FunctionLiteral = struct {
    parameters: ArrayList(Identifier),
    body: *Statement,

    pub fn format(value: FunctionLiteral, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = fmt;
        try writer.print("fn ({s}) {}", .{ value.parameters.items, value.body });
    }
};

pub const CallExpression = struct {
    expression: *Expression,
    arguments: ArrayList(Expression),

    pub fn format(value: CallExpression, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = fmt;
        try writer.print("{}({s})", .{ value.expression, value.arguments.items });
    }
};
