const std = @import("std");
const ArrayList = std.ArrayList;

const Parser = @import("../parser.zig").Parser;
const ast = @import("../ast.zig");
const Token = @import("../token.zig").Token;

pub const Precedence = enum {
    lowest,
    equality,
    comparison,
    addition,
    multiplication,
    prefix,
    call,
};

const ExpressionParseError = error{
    SuddenEOF,
    UnexpectedToken,
    ExpectedIdentifier,

    OutOfMemory,
};

pub fn parseIdentifier(self: *Parser) !ast.Expression {
    const token = self.next() orelse return error.SuddenEOF;
    if (token != .identifier) {
        return error.ExpectedIdentifier;
    }
    return .{ .identifier = .{ .name = token.identifier } };
}

pub fn parseBuiltin(self: *Parser) !ast.Expression {
    const token = self.next() orelse unreachable;
    return .{ .builtin = .{ .name = token.builtin } };
}

pub fn parseInteger(self: *Parser) !ast.Expression {
    const token = self.next() orelse unreachable;
    return .{ .integer = token.integer };
}

pub fn parseString(self: *Parser) !ast.Expression {
    const token = self.next() orelse unreachable;
    return .{ .string = token.string };
}

pub fn parseBoolean(self: *Parser) !ast.Expression {
    const token = self.next() orelse unreachable;
    return .{ .bool = (token == .true) };
}

pub fn parseNull(self: *Parser) !ast.Expression {
    self.assertNext(.null);
    return .null;
}

pub fn parsePrefixExpression(self: *Parser) !ast.Expression {
    const operator = self.next() orelse unreachable;

    const expression = try self.allocator.create(ast.Expression);
    expression.* = try self.parseExpressionPrecedence(.prefix);
    return .{ .unary = .{ .operator = operator, .expression = expression } };
}

pub fn parseGroupedExpression(self: *Parser) !ast.Expression {
    self.assertNext(.paren_l);

    var expression = try self.parseExpression();
    errdefer expression.deinit(self.allocator);

    try self.expectNext(.paren_r);
    return expression;
}

pub fn parseIfExpression(self: *Parser) !ast.Expression {
    self.assertNext(.if_);

    const condition = try self.allocator.create(ast.Expression);
    errdefer self.allocator.destroy(condition);
    condition.* = try self.parseExpression();
    errdefer condition.deinit(self.allocator);

    const then = try self.allocator.create(ast.Statement);
    errdefer self.allocator.destroy(then);
    then.* = try self.parseStatement() orelse return error.UnexpectedToken;
    errdefer then.*.deinit(self.allocator);

    var else_: ?*ast.Statement = null;
    errdefer {
        if (else_ != null) {
            self.allocator.destroy(else_.?);
        }
    }
    if (self.peek()) |peek| {
        if (peek == .else_) {
            else_ = try self.allocator.create(ast.Statement);
            self.advance();
            else_.?.* = try self.parseStatement() orelse return error.UnexpectedToken;
        }
    }

    return .{ .if_ = .{ .condition = condition, .then = then, .else_ = else_ } };
}

pub fn parseFunctionLiteral(self: *Parser) !ast.Expression {
    self.assertNext(.function);
    try self.expectNext(.paren_l);

    var parameters = ArrayList([]const u8).init(self.allocator);
    errdefer parameters.deinit();

    while (true) {
        const peek = self.peek() orelse return error.SuddenEOF;
        if (peek != .identifier) {
            break;
        }
        try parameters.append(peek.identifier);
        self.advance();
        const comma = self.peek() orelse return error.SuddenEOF;
        if (comma != .comma) {
            break;
        }
        self.advance();
    }
    try self.expectNext(.paren_r);

    const body = try self.allocator.create(ast.Statement);
    errdefer self.allocator.destroy(body);
    body.* = try self.parseStatement() orelse return error.UnexpectedToken;

    return .{ .function = .{ .parameters = try parameters.toOwnedSlice(), .body = body } };
}

pub fn callPrefixFunction(self: *Parser) !ast.Expression {
    const peek = self.peek() orelse return error.SuddenEOF;
    return switch (peek) {
        .identifier => self.parseIdentifier(),
        .builtin => self.parseBuiltin(),
        .integer => self.parseInteger(),
        .string => self.parseString(),
        .true, .false => self.parseBoolean(),
        .null => self.parseNull(),
        .minus, .bang => self.parsePrefixExpression(),
        .paren_l => self.parseGroupedExpression(),
        .if_ => self.parseIfExpression(),
        .function => self.parseFunctionLiteral(),
        else => error.UnexpectedToken,
    };
}

pub fn parseInfixExpression(self: *Parser, left: ast.Expression) !ast.Expression {
    const operator = self.next() orelse unreachable;
    const precedence = getPrecedence(operator) orelse unreachable;

    const left_ptr = try self.allocator.create(ast.Expression);
    errdefer self.allocator.destroy(left_ptr);
    left_ptr.* = left;

    const right = try self.allocator.create(ast.Expression);
    errdefer self.allocator.destroy(right);
    right.* = try self.parseExpressionPrecedence(precedence);

    return .{ .binary = .{ .left = left_ptr, .operator = operator, .right = right } };
}

pub fn parseCallExpression(self: *Parser, left: ast.Expression) !ast.Expression {
    self.assertNext(.paren_l);

    const function = try self.allocator.create(ast.Expression);
    function.* = left;
    errdefer {
        function.deinit(self.allocator);
        self.allocator.destroy(function);
    }

    var arguments = ArrayList(ast.Expression).init(self.allocator);
    errdefer {
        for (arguments.items) |*argument| {
            argument.deinit(self.allocator);
        }
        arguments.deinit();
    }

    while (true) {
        const peek = self.peek() orelse return error.SuddenEOF;
        if (peek == .paren_r) {
            break;
        }

        var expression = try self.parseExpression();
        errdefer expression.deinit(self.allocator);

        try arguments.append(expression);

        const comma = self.peek() orelse return error.SuddenEOF;
        if (comma != .comma) {
            break;
        }
        self.advance();
    }
    try self.expectNext(.paren_r);

    return .{ .call = .{ .function = function, .arguments = try arguments.toOwnedSlice() } };
}

pub fn callInfixFunction(self: *Parser, left: ast.Expression) !ast.Expression {
    const peek = self.peek() orelse unreachable;
    return try switch (peek) {
        .equal, .not_equal, .greater_than, .less_than, .plus, .minus, .asterisk, .slash => self.parseInfixExpression(left),
        .paren_l => self.parseCallExpression(left),
        else => unreachable,
    };
}

pub fn getPrecedence(token: Token) ?Precedence {
    return switch (token) {
        .equal, .not_equal => .equality,
        .greater_than, .less_than => .comparison,
        .plus, .minus => .addition,
        .asterisk, .slash => .multiplication,
        .paren_l => .call,
        else => null,
    };
}

pub fn parseExpressionPrecedence(self: *Parser, min_precedence: Precedence) ExpressionParseError!ast.Expression {
    var left = try self.callPrefixFunction();
    errdefer left.deinit(self.allocator);

    while (true) {
        const peek_token = self.peek() orelse break;
        const peek_precedence = getPrecedence(peek_token) orelse break;
        if (@intFromEnum(peek_precedence) <= @intFromEnum(min_precedence)) {
            break;
        }
        left = try self.callInfixFunction(left);
    }

    return left;
}

pub fn parseExpression(self: *Parser) !ast.Expression {
    return try self.parseExpressionPrecedence(.lowest);
}
