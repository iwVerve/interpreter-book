const std = @import("std");

const Lexer = @import("lexer.zig").Lexer;
const Parser = @import("parser.zig").Parser;
const Interpreter = @import("interpreter.zig").Interpreter;

pub fn main() !void {
    const source =
        \\let addN = fn(add) {
        \\  return fn(num) {
        \\      return num + add;
        \\  };
        \\};
        \\
        \\let addTwo = addN(2);
        \\
        \\addTwo(3);
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

    var interpreter = Interpreter.init(allocator);
    const result = try interpreter.eval(program);
    defer interpreter.deinit();

    const stdout = std.io.getStdOut();
    const stdout_writer = stdout.writer();
    var buffered_writer = std.io.bufferedWriter(stdout_writer);
    const writer = buffered_writer.writer();

    try writer.print("{any}\n", .{result});
    try buffered_writer.flush();
}
