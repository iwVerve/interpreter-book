const std = @import("std");
const token_zig = @import("token.zig");
const Token = token_zig.Token;
const TokenType = token_zig.TokenType;
const TokenPayload = token_zig.TokenPayload;

pub const Lexer = struct {
    source: []const u8,
    position: u32 = 0,
    row: u32 = 1,
    column: u32 = 1,

    pub fn nextToken(self: *Lexer) Token {
        self.skipWhitespace();

        const optional_char = self.nextChar();
        const char = optional_char orelse return .eof;
        switch (char) {
            '=' => {
                const next = self.peekChar();
                if (next == '=') {
                    _ = self.nextChar();
                    return .equal;
                }
                return .assign;
            },
            '!' => {
                const next = self.peekChar();
                if (next == '=') {
                    _ = self.nextChar();
                    return .not_equal;
                }
                return .bang;
            },
            '+' => return .plus,
            '-' => return .minus,
            '*' => return .asterisk,
            '/' => return .slash,
            '<' => return .less_than,
            '>' => return .greater_than,
            '(' => return .paren_l,
            ')' => return .paren_r,
            '{' => return .curly_l,
            '}' => return .curly_r,
            ',' => return .comma,
            ';' => return .semicolon,
            else => {
                if (isLetter(char)) {
                    const word = self.nextWord();
                    const keyword_token = getKeyword(word);
                    if (keyword_token) |token| {
                        return token;
                    }
                    return .{ .identifier = word };
                }
                if (isDigit(char)) {
                    const number = self.nextNumber();
                    return .{ .integer = number };
                }
            },
        }

        unreachable;
    }

    pub fn nextWord(self: *Lexer) []const u8 {
        const position = self.position - 1;
        while (true) {
            const char = self.peekChar().?;
            if (!isLetter(char)) {
                break;
            }
            _ = self.nextChar();
        }
        return self.source[position..self.position];
    }

    pub fn nextNumber(self: *Lexer) []const u8 {
        const position = self.position - 1;
        while (true) {
            const char = self.peekChar().?;
            if (!isDigit(char)) {
                break;
            }
            _ = self.nextChar();
        }
        return self.source[position..self.position];
    }

    pub fn peekChar(self: *Lexer) ?u8 {
        if (self.position >= self.source.len) {
            return undefined;
        }
        return self.source[self.position];
    }

    pub fn nextChar(self: *Lexer) ?u8 {
        if (self.position >= self.source.len) {
            return undefined;
        }
        const char = self.source[self.position];
        self.position += 1;
        return char;
    }

    fn getKeyword(word: []const u8) ?Token {
        if (std.mem.eql(u8, word, "fn")) {
            return .function;
        }
        if (std.mem.eql(u8, word, "let")) {
            return .let;
        }
        if (std.mem.eql(u8, word, "true")) {
            return .true;
        }
        if (std.mem.eql(u8, word, "false")) {
            return .false;
        }
        if (std.mem.eql(u8, word, "if")) {
            return .if_;
        }
        if (std.mem.eql(u8, word, "else")) {
            return .else_;
        }
        if (std.mem.eql(u8, word, "return")) {
            return .return_;
        }
        return undefined;
    }

    fn skipWhitespace(self: *Lexer) void {
        while (true) {
            const optional_char = self.peekChar();
            const char = optional_char orelse return;
            if (!isWhitespace(char)) {
                return;
            }
            _ = self.nextChar();
        }
    }

    fn isLetter(char: u8) bool {
        return (char >= 'a' and char <= 'z') or (char >= 'A' and char <= 'Z') or char == '_';
    }

    fn isDigit(char: u8) bool {
        return (char >= '0' and char <= '9');
    }

    fn isWhitespace(char: u8) bool {
        return switch (char) {
            ' ', '\t', '\n', '\r' => true,
            else => false,
        };
    }
};
