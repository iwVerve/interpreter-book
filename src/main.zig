const std = @import("std");

const Lexer = @import("lexer.zig").Lexer;
const Parser = @import("parser.zig").Parser;

pub fn main() !void {
    const source =
        \\let five = 5;
    ;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var lexer = Lexer{ .allocator = allocator };
    const tokens = try lexer.lex(source);
    defer allocator.free(tokens);

    var parser = Parser{ .allocator = allocator };
    const program = try parser.parse(tokens);

    std.debug.print("{any}\n", .{program});
}
