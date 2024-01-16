const std = @import("std");
const Token = @import("token.zig").Token;
const Lexer = @import("lexer.zig").Lexer;
const Parser = @import("parser.zig").Parser;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub const std_options = struct {
    pub const fmt_max_depth = 10;
};

pub fn main() !void {
    const string =
        \\let a = 12;
        \\return a;
        \\if (true) {let a = 5;}
    ;
    const statements = try Parser.parse(allocator, string);
    std.debug.print("{any}\n", .{statements.items});
}
