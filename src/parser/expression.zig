const std = @import("std");
const ArrayList = std.ArrayList;

const Parser = @import("../parser.zig").Parser;

const Token = @import("../token.zig").Token;
const TokenData = @import("../token.zig").TokenData;

const ParserError = @import("error.zig").ParserError;
const ParserErrors = @import("error.zig").ParserErrors;

const ast = @import("../ast.zig");
const Statement = ast.Statement;
const Expression = ast.Expression;
const Identifier = ast.Identifier;

const PrecedenceImpl = @import("precedence.zig");
const OperatorPrecedence = PrecedenceImpl.OperatorPrecedence;
const getPrecedence = PrecedenceImpl.getPrecedence;

pub fn parseExpression(self: *Parser, precedence: OperatorPrecedence) !Expression {
    const token = self.peekToken() orelse return ParserError.SuddenEOF;
    var left = try self.callPrefixFunction(token) orelse return ParserError.UnexpectedToken;
    while (true) {
        // Break if EOF or semicolon
        const peek = self.peekToken() orelse break;
        if (peek.data == TokenData.semicolon) {
            break;
        }
        // Break if no assigned infix function
        const peek_precedence = getPrecedence(peek) orelse break;
        // Break if lower precedence
        if (@intFromEnum(peek_precedence) < @intFromEnum(precedence)) {
            break;
        }
        const infix = self.peekToken() orelse unreachable;
        left = try self.callInfixFunction(infix, left) orelse unreachable;
    }
    return left;
}

pub fn callPrefixFunction(self: *Parser, token: Token) !?Expression {
    return switch (token.data) {
        .identifier => try self.parseIdentifierExpression(),
        .integer => try self.parseIntegerExpression(),
        .bang, .minus => try self.parsePrefixExpression(),
        .true_, .false_ => try self.parseBooleanExpression(),
        .paren_l => try self.parseGroupedExpression(),
        .if_ => try self.parseIfExpression(),
        .function => try self.parseFunctionExpression(),
        else => null,
    };
}

pub fn callInfixFunction(self: *Parser, token: Token, expression: Expression) !?Expression {
    return switch (token.data) {
        .plus,
        .minus,
        .asterisk,
        .slash,
        .equal,
        .not_equal,
        .less_than,
        .greater_than,
        => try self.parseInfixExpression(expression),
        .paren_l => try self.parseCallExpression(expression),
        else => null,
    };
}

pub fn parsePrefixExpression(self: *Parser) ParserErrors!Expression {
    const operator = self.nextToken() orelse return ParserError.SuddenEOF;
    const expression = try self.allocator.create(Expression);
    expression.* = try self.parseExpression(.prefix);

    return .{ .prefix_expression = .{ .operator = operator, .expression = expression } };
}

pub fn parseInfixExpression(self: *Parser, left: Expression) ParserErrors!Expression {
    const operator = self.nextToken() orelse return ParserError.SuddenEOF;
    const precedence = getPrecedence(operator) orelse return ParserError.UnexpectedToken;
    const left_ptr = try self.allocator.create(Expression);
    left_ptr.* = left;
    const right = try self.allocator.create(Expression);
    right.* = try self.parseExpression(precedence);
    return .{ .binary_expression = .{
        .lvalue = left_ptr,
        .operator = operator,
        .rvalue = right,
    } };
}

pub fn parseCallExpression(self: *Parser, left: Expression) ParserErrors!Expression {
    self.advanceToken(); // Guaranteed .paren_l
    const expression = try self.allocator.create(Expression);
    expression.* = left;
    const arguments = try self.parseCallArguments();
    return .{ .call_expression = .{ .expression = expression, .arguments = arguments } };
}

pub fn parseCallArguments(self: *Parser) ParserErrors!ArrayList(Expression) {
    var arguments = ArrayList(Expression).init(self.allocator);
    while (true) {
        try arguments.append(try self.parseExpression(.lowest));
        const peek = self.nextToken() orelse return ParserError.SuddenEOF;
        switch (peek.data) {
            .comma => {},
            .paren_r => break,
            else => return ParserError.UnexpectedToken,
        }
    }
    return arguments;
}

pub fn parseIfExpression(self: *Parser) ParserErrors!Expression {
    self.advanceToken(); // Guaranteed .if
    const condition = try self.allocator.create(Expression);
    condition.* = try self.parseExpression(.lowest);
    const then = try self.allocator.create(Statement);
    then.* = try self.parseStatement() orelse return ParserError.UnexpectedToken;
    var else_: ?*Statement = null;
    if (self.peekToken()) |peek| {
        if (peek.data == .else_) {
            self.advanceToken();
            else_ = try self.allocator.create(Statement);
            else_.?.* = try self.parseStatement() orelse return ParserError.UnexpectedToken;
        }
    }
    return .{ .if_expression = .{ .condition = condition, .then = then, .else_ = else_ } };
}

pub fn parseFunctionExpression(self: *Parser) ParserErrors!Expression {
    self.advanceToken(); // Guaranteed .function
    const paren_l = self.nextToken() orelse return ParserError.SuddenEOF;
    if (paren_l.data != .paren_l) {
        return ParserError.ExpectedParenL;
    }
    var parameters = ArrayList(Identifier).init(self.allocator);
    while (true) {
        try parameters.append(try self.parseIdentifier());
        const next = self.nextToken() orelse return ParserError.SuddenEOF;
        switch (next.data) {
            .comma => {},
            .paren_r => break,
            else => return ParserError.UnexpectedToken,
        }
    }
    const body = try self.allocator.create(Statement);
    body.* = try self.parseStatement() orelse return ParserError.UnexpectedToken;
    return .{ .function_literal = .{ .parameters = parameters, .body = body } };
}

pub fn parseIdentifierExpression(self: *Parser) !Expression {
    const identifier = try self.parseIdentifier();
    return .{ .identifier = identifier };
}

pub fn parseIntegerExpression(self: *Parser) !Expression {
    const integer = self.nextToken() orelse return ParserError.SuddenEOF;
    return .{ .integer_literal = .{ .token = integer, .value = try std.fmt.parseInt(i64, integer.data.integer, 10) } };
}

pub fn parseIdentifier(self: *Parser) !Identifier {
    const name = self.nextToken() orelse return ParserError.SuddenEOF;
    return .{
        .token = name,
        .name = name.data.identifier,
    };
}

pub fn parseBooleanExpression(self: *Parser) !Expression {
    const boolean = self.nextToken() orelse return ParserError.SuddenEOF;
    const value = switch (boolean.data) {
        .true_ => true,
        .false_ => false,
        else => return ParserError.UnexpectedToken,
    };
    return .{ .boolean_literal = .{
        .token = boolean,
        .value = value,
    } };
}

pub fn parseGroupedExpression(self: *Parser) ParserErrors!Expression {
    self.advanceToken(); // Guaranteed .paren_l
    const expression = try self.parseExpression(.lowest);
    const paren_r = self.peekToken() orelse return ParserError.SuddenEOF;
    if (paren_r.data != .paren_r) {
        return ParserError.ExpectedParenR;
    }
    self.advanceToken();
    return expression;
}
