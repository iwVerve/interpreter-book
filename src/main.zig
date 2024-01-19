const std = @import("std");
const Token = @import("token.zig").Token;
const Lexer = @import("lexer.zig").Lexer;
const Parser = @import("parser.zig").Parser;
const SerializeOptions = @import("serialize.zig").SerializeOptions;

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
    ;
    const statements = try Parser.parse(allocator, string);
    var options = SerializeOptions{
        .debug = false,
    };
    const writer = std.io.getStdOut().writer();
    for (statements.items) |statement| {
        try statement.write(writer, &options);
    }
}
