const std = @import("std");
const ArrayList = std.ArrayList;

const Lexer = @import("lexer.zig").Lexer;
const Token = @import("token.zig").Token;

const ast = @import("ast.zig");
const Statement = ast.Statement;

pub const Parser = struct {
    lexer: Lexer,
    current_token: ?Token = null,
    allocator: std.mem.Allocator,

    const ErrorImpl = @import("parser/error.zig");
    const ParserError = ErrorImpl.ParserError;
    const ParserErrors = ErrorImpl.ParserErrors;

    pub fn parse(allocator: std.mem.Allocator, input: []const u8) !ArrayList(Statement) {
        var lexer = Lexer.init(input);
        var parser = Parser{ .lexer = lexer, .allocator = allocator };
        parser.advanceToken();
        return try parser.parseStatements();
    }

    const StatementImpl = @import("parser/statement.zig");
    pub const parseStatements = StatementImpl.parseStatements;
    pub const parseStatement = StatementImpl.parseStatement;
    pub const parseLetStatement = StatementImpl.parseLetStatement;
    pub const parseReturnStatement = StatementImpl.parseReturnStatement;
    pub const parseExpressionStatement = StatementImpl.parseExpressionStatement;
    pub const parseBlockStatement = StatementImpl.parseBlockStatement;

    const ExpressionImpl = @import("parser/expression.zig");
    pub const parseExpression = ExpressionImpl.parseExpression;
    pub const callPrefixFunction = ExpressionImpl.callPrefixFunction;
    pub const parsePrefixExpression = ExpressionImpl.parsePrefixExpression;
    pub const callInfixFunction = ExpressionImpl.callInfixFunction;
    pub const parseInfixExpression = ExpressionImpl.parseInfixExpression;
    pub const parseGroupedExpression = ExpressionImpl.parseGroupedExpression;
    pub const parseCallExpression = ExpressionImpl.parseCallExpression;
    pub const parseCallArguments = ExpressionImpl.parseCallArguments;
    pub const parseIfExpression = ExpressionImpl.parseIfExpression;
    pub const parseFunctionExpression = ExpressionImpl.parseFunctionExpression;
    pub const parseIdentifierExpression = ExpressionImpl.parseIdentifierExpression;
    pub const parseIntegerExpression = ExpressionImpl.parseIntegerExpression;
    pub const parseBooleanExpression = ExpressionImpl.parseBooleanExpression;
    pub const parseIdentifier = ExpressionImpl.parseIdentifier;

    pub fn nextToken(self: *Parser) ?Token {
        const token = self.current_token;
        self.advanceToken();
        return token;
    }

    pub fn advanceToken(self: *Parser) void {
        self.current_token = self.lexer.nextToken();
    }

    pub fn peekToken(self: *Parser) ?Token {
        return self.current_token;
    }
};
