const std = @import("std");
const ArrayList = std.ArrayList;

const Lexer = @import("lexer.zig").Lexer;
const Token = @import("token.zig").Token;

const ast = @import("ast.zig");
const Statement = ast.Statement;
const BlockStatement = ast.BlockStatement;

pub const Parser = struct {
    lexer: Lexer,
    current_token: ?Token = null,
    allocator: std.mem.Allocator,

    const ErrorImpl = @import("parser/error.zig");
    const ParserError = ErrorImpl.ParserError;
    const ParserErrors = ErrorImpl.ParserErrors;

    const StatementParser = @import("parser/statement.zig");
    const ExpressionParser = @import("parser/expression.zig");

    pub fn parse(allocator: std.mem.Allocator, input: []const u8) !BlockStatement {
        var lexer = Lexer.init(input);
        var parser = Parser{ .lexer = lexer, .allocator = allocator };
        parser.advanceToken();
        const statements = try StatementParser.parseStatements(&parser);
        return .{ .statements = statements };
    }

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
