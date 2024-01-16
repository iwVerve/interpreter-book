const std = @import("std");
const ArrayList = std.ArrayList;
const Lexer = @import("lexer.zig").Lexer;
const Token = @import("token.zig").Token;
const TokenData = @import("token.zig").TokenData;

const ast = @import("ast.zig");
const Statement = ast.Statement;
const LetStatement = ast.LetStatement;
const Expression = ast.Expression;
const Identifier = ast.Identifier;

const ParserError = error{
    SuddenEOF,
    ExpectedAssign,
    ExpectedSemicolon,
    ExpectedParenL,
    UnexpectedToken,
};

pub const Parser = struct {
    lexer: Lexer,
    current_token: ?Token = null,
    allocator: std.mem.Allocator,

    pub fn parse(allocator: std.mem.Allocator, input: []const u8) !ArrayList(Statement) {
        var lexer = Lexer.init(input);
        var parser = Parser{ .lexer = lexer, .allocator = allocator };
        parser.advanceToken();
        return try parser.parseStatements();
    }

    fn parseStatements(self: *Parser) !ArrayList(Statement) {
        var statements = ArrayList(Statement).init(self.allocator);
        while (true) {
            const statement = (try self.parseStatement()) orelse break;
            try statements.append(statement);
        }
        return statements;
    }

    fn parseStatement(self: *Parser) !?Statement {
        const token = self.peekToken() orelse return null;
        return switch (token.data) {
            .let => try self.parseLetStatement(),
            .return_ => try self.parseReturnStatement(),
            else => ParserError.UnexpectedToken,
        };
    }

    fn parseLetStatement(self: *Parser) !Statement {
        self.advanceToken(); // Guaranteed .let
        const identifier = try self.parseIdentifier();
        const assign = self.nextToken() orelse return ParserError.SuddenEOF;
        if (assign.data != TokenData.assign) return ParserError.ExpectedAssign;
        const expression = try self.parseExpression();
        const semicolon = self.nextToken() orelse return ParserError.SuddenEOF;
        if (semicolon.data != TokenData.semicolon) return ParserError.ExpectedSemicolon;
        return .{ .let = .{
            .identifier = identifier,
            .expression = expression,
        } };
    }

    fn parseReturnStatement(self: *Parser) !Statement {
        self.advanceToken(); // Guaranteed .return
        const expression = try self.parseExpression();
        const semicolon = self.nextToken() orelse return ParserError.SuddenEOF;
        if (semicolon.data != TokenData.semicolon) return ParserError.ExpectedSemicolon;
        return .{ .return_ = .{
            .expression = expression,
        } };
    }

    fn parseIfStatement(self: *Parser) !Statement {
        self.advanceToken(); // Guaranteed .if
        const paren_l = self.nextToken() orelse return ParserError.SuddenEOF;
        if (paren_l.data != TokenData.paren_l) return ParserError.ExpectedParenL;
        const expression = try self.parseExpression();
        _ = expression;
    }

    fn parseExpression(self: *Parser) !Expression {
        const token = self.nextToken() orelse return ParserError.SuddenEOF;
        switch (token.data) {
            .integer => {
                return .{ .integer_literal = .{ .value = token } };
            },
            .identifier => {
                return .{ .identifier = .{ .name = token } };
            },
            else => return ParserError.UnexpectedToken,
        }
        const value = self.nextToken() orelse return ParserError.SuddenEOF;
        return .{ .integer_literal = .{ .value = value } };
    }

    fn parseIdentifier(self: *Parser) !Identifier {
        const name = self.nextToken() orelse return ParserError.SuddenEOF;
        return .{
            .name = name,
        };
    }

    fn nextToken(self: *Parser) ?Token {
        const token = self.current_token;
        self.advanceToken();
        return token;
    }

    fn advanceToken(self: *Parser) void {
        self.current_token = self.lexer.nextToken();
    }

    fn peekToken(self: *Parser) ?Token {
        return self.current_token;
    }
};
