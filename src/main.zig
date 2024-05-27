const std = @import("std");

const Lexer = @import("lexer.zig").Lexer;
const Parser = @import("parser.zig").Parser;

pub fn main() !void {
    const source =
        \\let result = -1 * 2 + 3 * -4;
        \\let swap = (1 + -2) * -(-3 + 4);
        \\return result;
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
    const stdout_writer = stdout.writer();
    var buffered_writer = std.io.bufferedWriter(stdout_writer);
    const writer = buffered_writer.writer();

    try program.write(writer);
    try buffered_writer.flush();
}
