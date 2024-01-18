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

    pub fn serialize(token_data: TokenData, options: *SerializeOptions) ![]const u8 {
        return try std.fmt.allocPrint(options.allocator, "{s}", .{switch (token_data) {
            .illegal => "ILLEGAL",

            .identifier => token_data.identifier,
            .integer => token_data.integer,

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
};

pub const Token = struct {
    data: TokenData,
    location: Location,
    length: u32,

    pub fn serialize(token: Token, options: *SerializeOptions) ![]const u8 {
        return try if (options.debug)
            std.fmt.allocPrint(options.allocator, "{s}@{}:{}", .{ try token.data.serialize(options), token.location.row, token.location.column })
        else
            std.fmt.allocPrint(options.allocator, "{s}", .{try token.data.serialize(options)});
    }
};
