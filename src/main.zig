const std = @import("std");
const Token = @import("token.zig").Token;
const Lexer = @import("lexer.zig").Lexer;
const Parser = @import("parser.zig").Parser;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub const std_options = struct {
    pub const fmt_max_depth = 10;
};

pub fn main() !void {
    const string =
        \\let foo = true * (1 + 2) + bar * 4;
        \\
        \\{
        \\  let a = b;
        \\  let b = c;
        \\  {
        \\      let c = d;
        \\  }
        \\}
        \\if true {
        \\  let a = 5;
        \\}
        \\else {
        \\  let b = 6;
        \\}
        \\
        \\let foo = if (x) {bar} else {baz};
        \\
        \\let add = fn(a, b) {
        \\  a + b
        \\};
        \\add(2, 3);
    ;
    const statements = try Parser.parse(allocator, string);
    for (statements.items) |statement| {
        std.debug.print("{}\n", .{statement});
    }
}
