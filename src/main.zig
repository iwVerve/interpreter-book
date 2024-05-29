const std = @import("std");

const Lexer = @import("lexer.zig").Lexer;
const Parser = @import("parser.zig").Parser;
const Interpreter = @import("interpreter.zig").Interpreter;

pub fn main() !void {
    const source =
        \\let double = fn(str) {
        \\  return str + str;
        \\};
        \\let str = "foo";
        \\let result = double(str);
        \\len(result);
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

    var interpreter = try Interpreter.init(allocator);
    const result = try interpreter.eval(program);
    defer interpreter.deinit();

    try writer.print("{any}\n", .{result});
    try buffered_writer.flush();
}
