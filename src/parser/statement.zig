const std = @import("std");
const ArrayList = std.ArrayList;

const TokenData = @import("../token.zig").TokenData;

const Parser = @import("../parser.zig").Parser;
const ast = @import("../ast.zig");
const Statement = ast.Statement;

const ParserError = @import("error.zig").ParserError;
const ParserErrors = @import("error.zig").ParserErrors;

pub fn parseStatements(self: *Parser) !ArrayList(Statement) {
    var statements = ArrayList(Statement).init(self.allocator);
    while (true) {
        const peek = self.peekToken() orelse break;
        if (peek.data == .curly_r) {
            break;
        }
        const statement = (try self.parseStatement()) orelse break;
        try statements.append(statement);
    }
    return statements;
}

pub fn parseStatement(self: *Parser) !?Statement {
    const token = self.peekToken() orelse return null;
    return switch (token.data) {
        .let => try self.parseLetStatement(),
        .return_ => try self.parseReturnStatement(),
        .curly_l => try self.parseBlockStatement(),
        else => try self.parseExpressionStatement(),
    };
}

pub fn parseLetStatement(self: *Parser) !Statement {
    self.advanceToken(); // Guaranteed .let
    const identifier = try self.parseIdentifier();
    const assign = self.nextToken() orelse return ParserError.SuddenEOF;
    if (assign.data != TokenData.assign) return ParserError.ExpectedAssign;
    const expression = try self.parseExpression(.lowest);
    const semicolon = self.nextToken() orelse return ParserError.SuddenEOF;
    if (semicolon.data != TokenData.semicolon) return ParserError.ExpectedSemicolon;
    return .{ .let = .{
        .identifier = identifier,
        .expression = expression,
    } };
}

pub fn parseReturnStatement(self: *Parser) !Statement {
    self.advanceToken(); // Guaranteed .return
    const expression = try self.parseExpression(.lowest);
    const semicolon = self.nextToken() orelse return ParserError.SuddenEOF;
    if (semicolon.data != TokenData.semicolon) return ParserError.ExpectedSemicolon;
    return .{ .return_ = .{
        .expression = expression,
    } };
}

pub fn parseExpressionStatement(self: *Parser) !Statement {
    const expression = try self.parseExpression(.lowest);

    // Optional semicolon
    const peek = self.peekToken();
    if (peek) |token| {
        if (token.data == .semicolon) {
            self.advanceToken();
        }
    }

    return .{ .expression = expression };
}

pub fn parseBlockStatement(self: *Parser) ParserErrors!Statement {
    self.advanceToken(); // Guaranteed.curly_l
    const statements = try self.parseStatements();
    const curly_r = self.nextToken() orelse return ParserError.SuddenEOF;
    if (curly_r.data != .curly_r) {
        return ParserError.ExpectedCurlyR;
    }
    return .{ .block = .{ .statements = statements } };
}
