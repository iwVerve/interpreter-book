const std = @import("std");
const Allocator = std.mem.Allocator;

const Token = @import("token.zig").Token;
const Ast = @import("ast.zig");

pub const Parser = struct {
    allocator: Allocator,
    source: []const Token = undefined,
    position: u32 = undefined,

    pub fn peek(self: Parser) ?Token {
        if (self.position >= self.source.len) {
            return null;
        }
        return self.source[self.position];
    }

    pub fn advance(self: *Parser) void {
        self.position += 1;
    }

    pub fn next(self: *Parser) ?Token {
        const token = self.peek();
        self.advance();
        return token;
    }

    const StatementImpl = @import("parser/statement.zig");
    pub const parseLetStatement = StatementImpl.parseLetStatement;
    pub const parseStatement = StatementImpl.parseStatement;
    pub const parseStatements = StatementImpl.parseStatements;

    const ExpressionImpl = @import("parser/expression.zig");
    pub const parseIdentifier = ExpressionImpl.parseIdentifier;
    pub const parseInteger = ExpressionImpl.parseInteger;
    pub const parseExpression = ExpressionImpl.parseExpression;

    pub fn expectNext(self: *Parser, comptime expect: Token) !void {
        const token = self.next() orelse return error.SuddenEOF;
        // @intFromEnum call possibly not ideal
        if (@intFromEnum(token) != @intFromEnum(expect)) {
            return error.UnexpectedToken;
        }
    }

    pub fn parse(self: *Parser, source: []const Token) !Ast.Statement {
        self.source = source;
        self.position = 0;

        return try self.parseStatements();
    }
};
