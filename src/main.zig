const std = @import("std");
const Parser = @import("parser.zig").Parser;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const StatementInterpreter = @import("interpreter.zig").StatementInterpreter;
const repl = @import("repl.zig");

pub fn main() !void {
    const string =
        \\let factorial = fn(n) {
        \\    if n == 0 {
        \\        return 1;
        \\    }
        \\    return n * factorial(n - 1);
        \\};
        \\
        \\factorial(5);
    ;
    const program = try Parser.parse(allocator, string);
    const result = try StatementInterpreter.evalProgram(program, allocator);

    const writer = std.io.getStdOut().writer();
    try result.write(writer);

    // try repl.start(allocator);
}
