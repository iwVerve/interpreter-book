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

const StatementParser = @import("statement.zig");

pub fn parseExpression(parser: *Parser, precedence: OperatorPrecedence) !Expression {
    const token = parser.peekToken() orelse return ParserError.SuddenEOF;
    var left = try callPrefixFunction(parser, token) orelse return ParserError.UnexpectedToken;
    while (true) {
        // Break if EOF or semicolon
        const peek = parser.peekToken() orelse break;
        if (peek.data == TokenData.semicolon) {
            break;
        }
        // Break if no assigned infix function
        const peek_precedence = getPrecedence(peek) orelse break;
        // Break if lower precedence
        if (@intFromEnum(peek_precedence) < @intFromEnum(precedence)) {
            break;
        }
        const infix = parser.peekToken() orelse unreachable;
        left = try callInfixFunction(parser, infix, left) orelse unreachable;
    }
    return left;
}

pub fn callPrefixFunction(parser: *Parser, token: Token) !?Expression {
    return switch (token.data) {
        .identifier => try parseIdentifierExpression(parser),
        .integer => try parseIntegerExpression(parser),
        .bang, .minus => try parsePrefixExpression(parser),
        .true_, .false_ => try parseBooleanExpression(parser),
        .paren_l => try parseGroupedExpression(parser),
        .if_ => try parseIfExpression(parser),
        .function => try parseFunctionExpression(parser),
        else => null,
    };
}

pub fn callInfixFunction(parser: *Parser, token: Token, expression: Expression) !?Expression {
    return switch (token.data) {
        .plus,
        .minus,
        .asterisk,
        .slash,
        .equal,
        .not_equal,
        .less_than,
        .greater_than,
        => try parseInfixExpression(parser, expression),
        .paren_l => try parseCallExpression(parser, expression),
        else => null,
    };
}

pub fn parsePrefixExpression(parser: *Parser) ParserErrors!Expression {
    const operator = parser.nextToken() orelse return ParserError.SuddenEOF;
    const expression = try parser.allocator.create(Expression);
    expression.* = try parseExpression(parser, .prefix);

    return .{ .prefix_expression = .{ .operator = operator, .expression = expression } };
}

pub fn parseInfixExpression(parser: *Parser, left: Expression) ParserErrors!Expression {
    const operator = parser.nextToken() orelse return ParserError.SuddenEOF;
    const precedence = getPrecedence(operator) orelse return ParserError.UnexpectedToken;
    const left_ptr = try parser.allocator.create(Expression);
    left_ptr.* = left;
    const right = try parser.allocator.create(Expression);
    right.* = try parseExpression(parser, precedence);
    return .{ .binary_expression = .{
        .lvalue = left_ptr,
        .operator = operator,
        .rvalue = right,
    } };
}

pub fn parseCallExpression(parser: *Parser, left: Expression) ParserErrors!Expression {
    parser.advanceToken(); // Guaranteed .paren_l
    const expression = try parser.allocator.create(Expression);
    expression.* = left;
    const arguments = try parseCallArguments(parser);
    return .{ .call_expression = .{ .expression = expression, .arguments = arguments } };
}

pub fn parseCallArguments(parser: *Parser) ParserErrors!ArrayList(Expression) {
    var arguments = ArrayList(Expression).init(parser.allocator);
    while (true) {
        try arguments.append(try parseExpression(parser, .lowest));
        const peek = parser.nextToken() orelse return ParserError.SuddenEOF;
        switch (peek.data) {
            .comma => {},
            .paren_r => break,
            else => return ParserError.UnexpectedToken,
        }
    }
    return arguments;
}

pub fn parseIfExpression(parser: *Parser) ParserErrors!Expression {
    parser.advanceToken(); // Guaranteed .if
    const condition = try parser.allocator.create(Expression);
    condition.* = try parseExpression(parser, .lowest);
    const then = try parser.allocator.create(Statement);
    then.* = try StatementParser.parseStatement(parser) orelse return ParserError.UnexpectedToken;
    var else_: ?*Statement = null;
    if (parser.peekToken()) |peek| {
        if (peek.data == .else_) {
            parser.advanceToken();
            else_ = try parser.allocator.create(Statement);
            else_.?.* = try StatementParser.parseStatement(parser) orelse return ParserError.UnexpectedToken;
        }
    }
    return .{ .if_expression = .{ .condition = condition, .then = then, .else_ = else_ } };
}

pub fn parseFunctionExpression(parser: *Parser) ParserErrors!Expression {
    parser.advanceToken(); // Guaranteed .function
    const paren_l = parser.nextToken() orelse return ParserError.SuddenEOF;
    if (paren_l.data != .paren_l) {
        return ParserError.ExpectedParenL;
    }
    var parameters = ArrayList(Identifier).init(parser.allocator);
    while (true) {
        const peek = parser.peekToken() orelse return ParserError.SuddenEOF;
        if (peek.data == .paren_r) {
            parser.advanceToken();
            break;
        }
        try parameters.append(try parseIdentifier(parser));
        const next = parser.nextToken() orelse return ParserError.SuddenEOF;
        switch (next.data) {
            .comma => {},
            .paren_r => break,
            else => return ParserError.UnexpectedToken,
        }
    }
    const body = try parser.allocator.create(Statement);
    body.* = try StatementParser.parseStatement(parser) orelse return ParserError.UnexpectedToken;
    return .{ .function_literal = .{ .parameters = parameters, .body = body } };
}

pub fn parseIdentifierExpression(parser: *Parser) !Expression {
    const identifier = try parseIdentifier(parser);
    return .{ .identifier = identifier };
}

pub fn parseIntegerExpression(parser: *Parser) !Expression {
    const integer = parser.nextToken() orelse return ParserError.SuddenEOF;
    return .{ .integer_literal = .{ .token = integer, .value = try std.fmt.parseInt(i64, integer.data.integer, 10) } };
}

pub fn parseIdentifier(parser: *Parser) !Identifier {
    const name = parser.nextToken() orelse return ParserError.SuddenEOF;
    return .{
        .token = name,
        .name = name.data.identifier,
    };
}

pub fn parseBooleanExpression(parser: *Parser) !Expression {
    const boolean = parser.nextToken() orelse return ParserError.SuddenEOF;
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

pub fn parseGroupedExpression(parser: *Parser) ParserErrors!Expression {
    parser.advanceToken(); // Guaranteed .paren_l
    const expression = try parseExpression(parser, .lowest);
    const paren_r = parser.peekToken() orelse return ParserError.SuddenEOF;
    if (paren_r.data != .paren_r) {
        return ParserError.ExpectedParenR;
    }
    parser.advanceToken();
    return expression;
}
