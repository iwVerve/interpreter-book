const Parser = @import("../parser.zig").Parser;
const Ast = @import("../ast.zig");
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
    ExpectedInteger,
    ExpectedBoolean,

    OutOfMemory,
};

pub fn parseIdentifier(self: *Parser) !Ast.Expression {
    const token = self.next() orelse return error.SuddenEOF;
    if (token != .identifier) {
        return error.ExpectedIdentifier;
    }
    return .{ .identifier = .{ .name = token.identifier } };
}

pub fn parseInteger(self: *Parser) !Ast.Expression {
    const token = self.next() orelse unreachable;
    if (token != .integer) {
        return error.ExpectedInteger;
    }
    return .{ .integer = token.integer };
}

pub fn parseBoolean(self: *Parser) !Ast.Expression {
    const token = self.next() orelse unreachable;
    if (token != .true and token != .false) {
        return error.ExpectedBoolean;
    }
    return .{ .bool_ = (token == .true) };
}

pub fn parsePrefixExpression(self: *Parser) !Ast.Expression {
    const operator = self.next() orelse unreachable;

    const expression = try self.allocator.create(Ast.Expression);
    expression.* = try self.parseExpressionPrecedence(.prefix);
    return .{ .unary = .{ .operator = operator, .expression = expression } };
}

pub fn parseGroupedExpression(self: *Parser) !Ast.Expression {
    self.assertNext(.paren_l);

    var expression = try self.parseExpression();
    errdefer expression.deinit(self.allocator);

    try self.expectNext(.paren_r);
    return expression;
}

pub fn callPrefixFunction(self: *Parser) !Ast.Expression {
    const peek = self.peek() orelse return error.SuddenEOF;
    return switch (peek) {
        .identifier => self.parseIdentifier(),
        .integer => self.parseInteger(),
        .true, .false => self.parseBoolean(),
        .minus, .bang => self.parsePrefixExpression(),
        .paren_l => self.parseGroupedExpression(),
        else => error.UnexpectedToken,
    };
}

pub fn parseInfixExpression(self: *Parser, left: Ast.Expression) !Ast.Expression {
    const operator = self.next() orelse unreachable;
    const precedence = getPrecedence(operator) orelse unreachable;

    const left_ptr = try self.allocator.create(Ast.Expression);
    errdefer self.allocator.destroy(left_ptr);
    left_ptr.* = left;

    const right = try self.allocator.create(Ast.Expression);
    errdefer self.allocator.destroy(right);
    right.* = try self.parseExpressionPrecedence(precedence);

    return .{ .binary = .{ .left = left_ptr, .operator = operator, .right = right } };
}

pub fn callInfixFunction(self: *Parser, left: Ast.Expression) !Ast.Expression {
    const peek = self.peek() orelse unreachable;
    return try switch (peek) {
        .equal, .not_equal, .greater_than, .less_than, .plus, .minus, .asterisk, .slash => self.parseInfixExpression(left),
        else => unreachable,
    };
}

pub fn getPrecedence(token: Token) ?Precedence {
    return switch (token) {
        .equal, .not_equal => .equality,
        .greater_than, .less_than => .comparison,
        .plus, .minus => .addition,
        .asterisk, .slash => .multiplication,
        else => null,
    };
}

pub fn parseExpressionPrecedence(self: *Parser, min_precedence: Precedence) ExpressionParseError!Ast.Expression {
    var left = try self.callPrefixFunction();
    errdefer left.deinit(self.allocator);

    while (true) {
        const peek_token = self.peek() orelse break;
        const peek_precedence = getPrecedence(peek_token) orelse break;
        if (@intFromEnum(peek_precedence) < @intFromEnum(min_precedence)) {
            break;
        }
        left = try self.callInfixFunction(left);
    }

    return left;
}

pub fn parseExpression(self: *Parser) !Ast.Expression {
    return try self.parseExpressionPrecedence(.lowest);
}
