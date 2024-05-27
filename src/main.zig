const std = @import("std");

const Lexer = @import("lexer.zig").Lexer;
const Parser = @import("parser.zig").Parser;

pub fn main() !void {
    const source =
        \\let add = fn(a, b) {
        \\  let result = a + b;
        \\  return result;
        \\};
        \\let sum = if (true) {
        \\  return add(2, 3);
        \\}
        \\else {
        \\  return add(3, 4);
        \\};
    ;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var lexer = Lexer{ .allocator = allocator };
    const tokens = try lexer.lex(source);
    defer {
        for (tokens) |*token| {
            token.deinit(allocator);
        }
        allocator.free(tokens);
    }

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
