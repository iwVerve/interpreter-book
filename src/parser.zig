const std = @import("std");
const Allocator = std.mem.Allocator;

const Token = @import("token.zig").Token;
const TokenTag = @typeInfo(Token).Union.tag_type.?;
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
    pub usingnamespace StatementImpl;

    const ExpressionImpl = @import("parser/expression.zig");
    pub usingnamespace ExpressionImpl;

    pub fn expectNext(self: *Parser, comptime expect: TokenTag) !void {
        const token = self.next() orelse return error.SuddenEOF;
        if (token != expect) {
            return error.UnexpectedToken;
        }
    }

    pub fn assertNext(self: *Parser, comptime expect: TokenTag) void {
        const token = self.next() orelse unreachable;
        if (token != expect) {
            unreachable;
        }
    }

    /// Caller owns returned memory.
    pub fn parse(self: *Parser, source: []const Token) !Ast.Statement {
        self.source = source;
        self.position = 0;

        var program = try self.parseStatements();
        errdefer program.deinit(self.allocator);

        if (self.position < self.source.len) {
            return error.ParserEndedEarly;
        }

        return program;
    }
};
