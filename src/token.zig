const std = @import("std");

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

    pub fn format(value: TokenData, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = fmt;
        switch (value) {
            .identifier => {
                try writer.print("\"{s}\"", .{value.identifier});
            },
            .integer => {
                try writer.print("\"{s}\"", .{value.integer});
            },
            else => {
                try writer.print("{}", .{value});
            },
        }
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

    pub fn format(value: Token, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = fmt;
        try writer.print("<< {?} at {}:{} >>", .{ value.data, value.location.row, value.location.column });
    }
};
