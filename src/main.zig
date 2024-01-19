const std = @import("std");
const Token = @import("token.zig").Token;
const Lexer = @import("lexer.zig").Lexer;
const Parser = @import("parser.zig").Parser;
const SerializeOptions = @import("ast/serialize.zig").SerializeOptions;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    const string =
        \\let a = 1;
        \\let b = fn() {
        \\  return 2;
        \\};
        \\let factorial = fn(n) {
        \\  if n < 2 {
        \\      return 1;
        \\  }
        \\  return n * factorial(n - 1);
        \\};
        \\return if true {1} else {2};
        \\if (true) {
        \\  print(foo);
        \\}
        \\else {
        \\  print(bar);
        \\}
        \\let c = 1 * 2 + 3 * 4 + 5 * 6;
        \\let d = 1 * (2 + 3) * (4 + 5) * 6;
        \\let e = -(1 + 2);
    ;
    const program = try Parser.parse(allocator, string);
    var options = SerializeOptions{
        .debug = false,
    };
    const writer = std.io.getStdOut().writer();
    try program.write(writer, &options);
}
