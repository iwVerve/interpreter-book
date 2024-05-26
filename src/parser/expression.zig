const Parser = @import("../parser.zig").Parser;
const Ast = @import("../ast.zig");

const Priority = enum {
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
    const token = self.next() orelse return error.SuddenEOF;
    if (token != .integer) {
        return error.ExpectedInteger;
    }
    return .{ .integer = token.integer };
}

pub fn parsePrefixExpression(self: *Parser) !Ast.Expression {
    const operator = self.next() orelse unreachable;

    const expression = try self.allocator.create(Ast.Expression);
    expression.* = try self.parseExpressionPriority(.prefix);
    return .{ .unary = .{ .operator = operator, .expression = expression } };
}

pub fn callPrefixFunction(self: *Parser) !Ast.Expression {
    const peek = self.peek() orelse return error.SuddenEOF;
    return switch (peek) {
        .identifier => self.parseIdentifier(),
        .integer => self.parseInteger(),
        .plus, .minus => self.parsePrefixExpression(),
        else => error.UnexpectedToken,
    };
}

pub fn callInfixFunction(self: *Parser, left: Ast.Expression) !Ast.Expression {
    _ = self;
    _ = left;
}

pub fn parseExpressionPriority(self: *Parser, priority: Priority) ExpressionParseError!Ast.Expression {
    const left = try self.callPrefixFunction();

    _ = priority;

    return left;
}

pub fn parseExpression(self: *Parser) !Ast.Expression {
    return try self.parseExpressionPriority(.lowest);
}
