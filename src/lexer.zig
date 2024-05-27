const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const Config = @import("Config.zig");

const TokenImpl = @import("token.zig");
const Token = TokenImpl.Token;
const operators = TokenImpl.operators;
const keywords = TokenImpl.keywords;

pub const Lexer = struct {
    source: []const u8 = undefined,
    position: u32 = undefined,
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

        const integer_string = self.source[integer_start..self.position];
        const integer = try std.fmt.parseInt(Config.integer_type, integer_string, 10);

        return .{ .integer = integer };
    }

    fn isOperator(char: u8) bool {
        // Construct array of all operator chars from operator array.
        const operator_chars = comptime blk: {
            var chars: []const u8 = &.{};

            for (operators) |operator| {
                unq: for (operator[0]) |operator_char| {
                    for (chars) |check_char| {
                        if (operator_char == check_char) {
                            continue :unq;
                        }
                    }
                    const array: []const u8 = &.{operator_char};
                    chars = chars ++ array;
                }
            }

            break :blk chars;
        };

        for (operator_chars) |operator_char| {
            if (char == operator_char) {
                return true;
            }
        }
        return false;
    }

    fn matchOperator(self: *Lexer, operator: []const u8) ?Token {
        // Match operator against operator array
        // Could be optimized since operator length is known at each function call
        inline for (operators) |operator_tuple| {
            const operator_string = operator_tuple[0];
            if (std.mem.eql(u8, operator, operator_string)) {
                for (1..operator.len) |_| {
                    self.advance();
                }
                return operator_tuple[1];
            }
        }
        return null;
    }

    fn readOperator(self: *Lexer) Token {
        const start = self.position;
        self.advance();
        const peek_char = self.peek();

        // Check for 2-wide operator first
        if (peek_char) |next_char| {
            if (isOperator(next_char)) {
                const long_operator = self.source[start .. start + 2];
                if (self.matchOperator(long_operator)) |token| {
                    return token;
                }
            }
        }

        const operator = self.source[start .. start + 1];
        if (self.matchOperator(operator)) |token| {
            return token;
        }

        unreachable;
    }

    fn isLetter(char: u8) bool {
        return switch (char) {
            'a'...'z', 'A'...'Z', '_' => true,
            else => false,
        };
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
        if (getKeyword(word)) |keyword| {
            return keyword;
        }

        const word_ptr = try self.allocator.alloc(u8, word.len);
        @memcpy(word_ptr, word);

        return .{ .identifier = word_ptr };
    }

    fn getKeyword(word: []const u8) ?Token {
        inline for (keywords) |keyword_tuple| {
            if (std.mem.eql(u8, word, keyword_tuple[0])) {
                return keyword_tuple[1];
            }
        }

        return null;
    }

    /// Caller owns returned memory.
    /// Doesn't point to but doesn't consume source.
    pub fn lex(self: *Lexer, source: []const u8) ![]Token {
        self.source = source;
        self.position = 0;
        var tokens = ArrayList(Token).init(self.allocator);
        errdefer tokens.deinit();

        while (self.peek()) |peek_char| {
            if (isWhitespace(peek_char)) {
                self.consumeWhitespace();
            } else if (isDigit(peek_char)) {
                try tokens.append(try self.readInteger());
            } else if (isOperator(peek_char)) {
                try tokens.append(self.readOperator());
            } else if (isLetter(peek_char)) {
                try tokens.append(try self.readWord());
            } else {
                return error.UnknownCharacter;
            }
        }

        return try tokens.toOwnedSlice();
    }
};
