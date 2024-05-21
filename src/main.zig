const std = @import("std");

const Lexer = @import("lexer.zig").Lexer;

pub fn main() !void {
    const source =
        \\let five = 5;
        \\let ten = 10;
        \\
        \\let add = fn(x, y) {
        \\    x + y;
        \\};
        \\
        \\let result = add(five, ten);
    ;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var lexer = Lexer{ .source = source, .allocator = allocator };
    const tokens = try lexer.lex();
    defer tokens.deinit();
}
