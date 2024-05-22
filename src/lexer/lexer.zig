const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Token = @import("../token.zig").Token;

pub const Lexer = struct {
    source: []const u8,
    position: u32 = 0,
    allocator: Allocator,

    fn peek(self: Lexer) ?u8 {
        if (self.position >= self.source.len) {
            return null;
        }
        return self.source[self.position];
    }

    fn advance(self: *Lexer) void {
        self.position += 1;
    }

    fn next(self: *Lexer) ?u8 {
        const char = self.peek();
        self.advance();
        return char;
    }

    fn isWhitespace(char: u8) bool {
        return switch (char) {
            ' ', '\t', '\n', '\r' => true,
            else => false,
        };
    }

    fn consumeWhitespace(self: *Lexer) void {
        while (self.peek()) |peek_char| {
            if (!isWhitespace(peek_char)) {
                break;
            }

            self.advance();
        }
    }

    fn isDigit(char: u8) bool {
        return char >= '0' and char <= '9';
    }

    fn readInteger(self: *Lexer) !Token {
        const integer_start = self.position;

        while (self.peek()) |peek_char| {
            if (!isDigit(peek_char)) {
                break;
            }

            self.advance();
        }

        const integer = self.source[integer_start..self.position];
        std.debug.print("{s}\n", .{integer});

        return .integer;
    }

    fn isLetter(char: u8) bool {
        return (char >= 'a' and char <= 'z') or (char >= 'A' and char <= 'Z') or char == '_';
    }

    fn readWord(self: *Lexer) !Token {
        const word_start = self.position;

        while (self.peek()) |peek_char| {
            if (!isDigit(peek_char) and !(isLetter(peek_char))) {
                break;
            }

            self.advance();
        }

        const word = self.source[word_start..self.position];
        std.debug.print("{s}\n", .{word});

        return .identifier;
    }

    pub fn lex(self: *Lexer) !ArrayList(Token) {
        var tokens = ArrayList(Token).init(self.allocator);

        while (self.peek()) |peek_char| {
            if (isWhitespace(peek_char)) {
                self.consumeWhitespace();
            } else if (isDigit(peek_char)) {
                try tokens.append(try self.readInteger());
            } else if (isLetter(peek_char)) {
                try tokens.append(try self.readWord());
            } else { // TODO: Special characters
                self.advance();
            }
        }

        return tokens;
    }
};
