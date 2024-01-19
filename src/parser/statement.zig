const std = @import("std");
const ArrayList = std.ArrayList;

const TokenData = @import("../token.zig").TokenData;

const Parser = @import("../parser.zig").Parser;
const ast = @import("../ast.zig");
const Statement = ast.Statement;

const ParserError = @import("error.zig").ParserError;
const ParserErrors = @import("error.zig").ParserErrors;

const ExpressionParser = @import("expression.zig");

pub fn parseStatements(parser: *Parser) !ArrayList(Statement) {
    var statements = ArrayList(Statement).init(parser.allocator);
    while (true) {
        const peek = parser.peekToken() orelse break;
        if (peek.data == .curly_r) {
            break;
        }
        const statement = (try parseStatement(parser)) orelse break;
        try statements.append(statement);
    }
    return statements;
}
pub fn parseStatement(parser: *Parser) !?Statement {
    const token = parser.peekToken() orelse return null;
    return switch (token.data) {
        .let => try parseLetStatement(parser),
        .return_ => try parseReturnStatement(parser),
        .curly_l => try parseBlockStatement(parser),
        else => try parseExpressionStatement(parser),
    };
}

pub fn parseLetStatement(parser: *Parser) !Statement {
    parser.advanceToken(); // Guaranteed .let
    const identifier = try ExpressionParser.parseIdentifier(parser);
    const assign = parser.nextToken() orelse return ParserError.SuddenEOF;
    if (assign.data != TokenData.assign) return ParserError.ExpectedAssign;
    const expression = try ExpressionParser.parseExpression(parser, .lowest);
    const semicolon = parser.nextToken() orelse return ParserError.SuddenEOF;
    if (semicolon.data != TokenData.semicolon) return ParserError.ExpectedSemicolon;
    return .{ .let = .{
        .identifier = identifier,
        .expression = expression,
    } };
}

pub fn parseReturnStatement(parser: *Parser) !Statement {
    parser.advanceToken(); // Guaranteed .return
    const expression = try ExpressionParser.parseExpression(parser, .lowest);
    const semicolon = parser.nextToken() orelse return ParserError.SuddenEOF;
    if (semicolon.data != TokenData.semicolon) return ParserError.ExpectedSemicolon;
    return .{ .return_ = .{
        .expression = expression,
    } };
}

pub fn parseExpressionStatement(parser: *Parser) !Statement {
    const expression = try ExpressionParser.parseExpression(parser, .lowest);

    // Optional semicolon
    const peek = parser.peekToken();
    if (peek) |token| {
        if (token.data == .semicolon) {
            parser.advanceToken();
        }
    }

    return .{ .expression = expression };
}

pub fn parseBlockStatement(parser: *Parser) ParserErrors!Statement {
    parser.advanceToken(); // Guaranteed.curly_l
    const statements = try parseStatements(parser);
    const curly_r = parser.nextToken() orelse return ParserError.SuddenEOF;
    if (curly_r.data != .curly_r) {
        return ParserError.ExpectedCurlyR;
    }
    return .{ .block = .{ .statements = statements } };
}
