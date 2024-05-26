const std = @import("std");

const Lexer = @import("lexer.zig").Lexer;
const Parser = @import("parser.zig").Parser;

pub fn main() !void {
    const source =
        \\let five = 5;
        \\return 254;
    ;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var lexer = Lexer{ .allocator = allocator };
    const tokens = try lexer.lex(source);
    defer allocator.free(tokens);

    var parser = Parser{ .allocator = allocator };
    var program = try parser.parse(tokens);
    defer program.deinit(allocator);

    const stdout = std.io.getStdOut();
    const writer = stdout.writer();
    try program.write(writer);
}
