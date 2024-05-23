const std = @import("std");

const Lexer = @import("lexer.zig").Lexer;

pub fn main() !void {
    const source =
        \\let five = 5;
        \\if (five < 10) {
        \\    return true;
        \\}
        \\else if (five == 5) {
        \\    return false;
        \\}
    ;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var lexer = Lexer{ .source = source, .allocator = allocator };
    const tokens = try lexer.lex();
    defer tokens.deinit();

    for (tokens.items) |token| {
        std.debug.print("{any}\n", .{token});
    }
}
