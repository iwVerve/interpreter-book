const std = @import("std");
const SerializeOptions = @import("serialize.zig").SerializeOptions;

pub const TokenData = union(enum) {
    // Meta
    illegal,

    // Identifiers, literals
    identifier: []const u8,
    integer: []const u8,

    // Operators
    assign,
    plus,
    minus,
    asterisk,
    slash,
    bang,

    equal,
    not_equal,
    less_than,
    greater_than,

    // Delimiters
    comma,
    semicolon,

    paren_l,
    paren_r,
    curly_l,
    curly_r,

    // Keywords
    let,
    function,
    true_,
    false_,
    if_,
    else_,
    return_,

    // pub fn serialize(token_data: TokenData, options: *SerializeOptions) ![]const u8 {
    pub fn write(self: TokenData, writer: anytype, options: *SerializeOptions) !void {
        _ = options;
        try writer.print("{s}", .{switch (self) {
            .illegal => "ILLEGAL",

            .identifier => self.identifier,
            .integer => self.integer,

            .assign => "=",
            .plus => "+",
            .minus => "-",
            .asterisk => "*",
            .slash => "/",
            .bang => "!",

            .equal => "==",
            .not_equal => "!=",
            .less_than => "<",
            .greater_than => ">",

            .comma => ",",
            .semicolon => ";",

            .paren_l => "(",
            .paren_r => ")",
            .curly_l => "{",
            .curly_r => "}",

            .let => "let",
            .function => "fn",
            .true_ => "true",
            .false_ => "false",
            .if_ => "if",
            .else_ => "else",
            .return_ => "return",
        }});
    }
};

pub const Location = struct {
    row: u32,
    column: u32,

    pub fn write(self: Location, writer: anytype, options: *SerializeOptions) !void {
        _ = options;
        _ = try writer.print("{}:{}", .{ self.row, self.column });
    }
};

pub const Token = struct {
    data: TokenData,
    location: Location,
    length: u32,

    pub fn write(self: Token, writer: anytype, options: *SerializeOptions) !void {
        try self.data.write(writer, options);
        if (options.debug) {
            _ = try writer.write("@");
            try self.location.write(writer, options);
        }
    }
};
