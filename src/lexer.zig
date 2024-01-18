const std = @import("std");
const Token = @import("token.zig").Token;
const TokenData = @import("token.zig").TokenData;
const Location = @import("token.zig").Location;

pub const Lexer = struct {
    input: []const u8 = undefined,
    position: u32 = 0,
    row: u32 = 1,
    column: u32 = 1,

    pub fn init(input: []const u8) Lexer {
        return .{
            .input = input,
        };
    }

    pub fn nextToken(self: *Lexer) ?Token {
        self.skipWhitespace();

        const start = self.position;
        const location: Location = .{ .row = self.row, .column = self.column };
        const char = self.nextChar() orelse return null;
        const token_data: TokenData = switch (char) {
            '=' => blk: {
                const next = self.peekChar() orelse break :blk .assign;
                if (next == '=') {
                    self.advanceChar();
                    break :blk .equal;
                }
                break :blk .assign;
            },
            '+' => .plus,
            '-' => .minus,
            '*' => .asterisk,
            '/' => .slash,
            '!' => blk: {
                const next = self.peekChar() orelse break :blk .bang;
                if (next == '=') {
                    self.advanceChar();
                    break :blk .not_equal;
                }
                break :blk .bang;
            },

            '<' => .less_than,
            '>' => .greater_than,

            ',' => .comma,
            ';' => .semicolon,

            '(' => .paren_l,
            ')' => .paren_r,
            '{' => .curly_l,
            '}' => .curly_r,

            else => blk: {
                if (isLetter(char)) {
                    const word = self.readWord();
                    if (std.mem.eql(u8, word, "let")) {
                        break :blk .let;
                    }
                    if (std.mem.eql(u8, word, "fn")) {
                        break :blk .function;
                    }
                    if (std.mem.eql(u8, word, "if")) {
                        break :blk .if_;
                    }
                    if (std.mem.eql(u8, word, "else")) {
                        break :blk .else_;
                    }
                    if (std.mem.eql(u8, word, "true")) {
                        break :blk .true_;
                    }
                    if (std.mem.eql(u8, word, "false")) {
                        break :blk .false_;
                    }
                    if (std.mem.eql(u8, word, "return")) {
                        break :blk .return_;
                    }
                    break :blk .{ .identifier = word };
                }
                if (isDigit(char)) {
                    const number = self.readNumber();
                    break :blk .{ .integer = number };
                }
                break :blk .illegal;
            },
        };

        const length = self.position - start;
        return .{ .data = token_data, .location = location, .length = length };
    }

    fn readWord(self: *Lexer) []const u8 {
        const start = self.position - 1;
        while (true) {
            const char = self.peekChar() orelse break;
            if (isLetter(char)) {
                self.advanceChar();
            } else {
                break;
            }
        }
        const end = self.position;
        return self.input[start..end];
    }

    fn readNumber(self: *Lexer) []const u8 {
        const start = self.position - 1;
        while (true) {
            const char = self.peekChar() orelse break;
            if (isDigit(char)) {
                self.advanceChar();
            } else {
                break;
            }
        }
        const end = self.position;
        return self.input[start..end];
    }

    fn isLetter(char: u8) bool {
        return (char >= 'a' and char <= 'z') or (char >= 'A' and char <= 'Z') or char == '_';
    }

    fn isDigit(char: u8) bool {
        return (char >= '0' and char <= '9');
    }

    fn skipWhitespace(self: *Lexer) void {
        while (true) {
            const char = self.peekChar() orelse return;
            switch (char) {
                ' ', '\t', '\n', '\r' => {
                    self.advanceChar();
                },
                else => return,
            }
        }
    }

    fn nextChar(self: *Lexer) ?u8 {
        if (self.position >= self.input.len) {
            return null;
        }
        self.advanceChar();
        return self.input[self.position - 1];
    }

    fn advanceChar(self: *Lexer) void {
        const char = self.peekChar() orelse return;
        if (char == '\n') {
            self.row += 1;
            self.column = 1;
        } else {
            self.column += 1;
        }
        self.position += 1;
    }

    fn peekChar(self: Lexer) ?u8 {
        if (self.position >= self.input.len) {
            return null;
        }
        return self.input[self.position];
    }
};
