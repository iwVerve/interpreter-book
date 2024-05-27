const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Config = @import("Config.zig");

/// Owns own memory.
pub const Token = union(enum) {
    identifier: []const u8,
    integer: Config.integer_type,

    assign,
    plus,
    minus,
    bang,
    asterisk,
    slash,

    equal,
    not_equal,
    less_than,
    greater_than,

    comma,
    semicolon,

    paren_l,
    paren_r,
    brace_l,
    brace_r,

    function,
    let,
    true,
    false,
    if_,
    else_,
    return_,

    pub fn deinit(self: *Token, allocator: Allocator) void {
        if (self.* == .identifier) {
            allocator.free(self.identifier);
        }
    }

    pub fn write(self: Token, writer: anytype) !void {
        if (self == .identifier) {
            try writer.print("{s}", .{self.identifier});
            return;
        }
        if (self == .integer) {
            try writer.print("{}", .{self.integer});
            return;
        }
        inline for (operators) |operator| {
            if (self == operator[1]) {
                try writer.print("{s}", .{operator[0]});
                return;
            }
        }
        inline for (keywords) |keyword| {
            if (self == keyword[1]) {
                try writer.print("{s}", .{keyword[0]});
                return;
            }
        }
        try writer.print("?", .{});
        return;
    }
};

pub const operators = .{
    .{ "=", .assign },

    .{ "+", .plus },
    .{ "-", .minus },
    .{ "*", .asterisk },
    .{ "/", .slash },
    .{ "!", .bang },

    .{ "==", .equal },
    .{ "!=", .not_equal },
    .{ "<", .less_than },
    .{ ">", .greater_than },

    .{ ",", .comma },
    .{ ";", .semicolon },

    .{ "(", .paren_l },
    .{ ")", .paren_r },
    .{ "{", .brace_l },
    .{ "}", .brace_r },
};

pub const keywords = .{
    .{ "let", .let },
    .{ "fn", .function },
    .{ "true", .true },
    .{ "false", .false },
    .{ "if", .if_ },
    .{ "else", .else_ },
    .{ "return", .return_ },
};
