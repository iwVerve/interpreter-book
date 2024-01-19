const std = @import("std");
const Token = @import("token.zig").Token;
const Lexer = @import("lexer.zig").Lexer;
const Parser = @import("parser.zig").Parser;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const StatementInterpreter = @import("interpreter.zig").StatementInterpreter;

pub fn main() !void {
    const string =
        \\5
    ;
    const program = try Parser.parse(allocator, string);
    const result = try StatementInterpreter.evalBlockStatement(program);

    const writer = std.io.getStdOut().writer();
    try result.write(writer);
}
