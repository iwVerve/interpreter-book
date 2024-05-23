const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Token = @import("../token.zig").Token;

const operators = .{
    .{ "=", .assign },
    .{ "=", .assign },
    .{ "+", .add },
    .{ ",", .comma },
    .{ ";", .semicolon },
    .{ "(", .paren_l },
    .{ ")", .paren_r },
    .{ "{", .brace_l },
    .{ "}", .brace_r },
};

const keywords = .{
    .{ "let", .let },
    .{ "fn", .function },
};

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

        const integer_string = self.source[integer_start..self.position];
        const integer = try std.fmt.parseInt(u32, integer_string, 10);

        return .{ .integer = integer };
    }

    fn isOperator(char: u8) bool {
        const operator_chars = comptime blk: {
            var chars: []const u8 = &.{};

            for (operators) |operator| {
                for (operator[0]) |operator_char| {
                    const array: []const u8 = &.{operator_char};
                    chars = chars ++ array;
                }
            }

            break :blk chars;
        };
        // @compileLog(operator_chars);

        for (operator_chars) |operator_char| {
            if (char == operator_char) {
                return true;
            }
        }
        return false;
    }

    fn readOperator(self: *Lexer) Token {
        const first_char = self.next() orelse unreachable;
        const peek_char = self.peek();

        if (peek_char) |second_char| {
            if (isOperator(second_char)) {
                inline for (operators) |operator_tuple| {
                    const operator_string = operators[0];
                    if (operator_string.len != 2) {
                        continue;
                    }
                    if (first_char != operator_string[0]) {
                        continue;
                    }
                    if (second_char == operator_string[1]) {
                        return operator_tuple[1];
                    }
                }
            }
        }

        inline for (operators) |operator_tuple| {
            const operator_string = operators[0];
            if (operator_string.len != 1) {
                continue;
            }
            if (first_char == operator_string[0]) {
                return operator_tuple[1];
            }
        }
    }

    fn isLetter(char: u8) bool {
        return switch (char) {
            'a'...'z', 'A'...'Z', '_' => true,
            else => false,
        };
    }

    fn readWord(self: *Lexer) Token {
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

        return .{ .identifier = word };
    }

    fn getKeyword(word: []const u8) ?Token {
        inline for (keywords) |keyword_tuple| {
            if (std.mem.eql(u8, word, keyword_tuple[0])) {
                return keyword_tuple[1];
            }
        }

        return null;
    }

    pub fn lex(self: *Lexer) !ArrayList(Token) {
        var tokens = ArrayList(Token).init(self.allocator);

        while (self.peek()) |peek_char| {
            if (isWhitespace(peek_char)) {
                self.consumeWhitespace();
            } else if (isDigit(peek_char)) {
                try tokens.append(try self.readInteger());
            } else if (isLetter(peek_char)) {
                try tokens.append(self.readWord());
            } else if (isOperator(peek_char)) {
                try tokens.append(self.readOperator());
            } else {
                return error.UnknownCharacter;
            }
        }

        return tokens;
    }
};
