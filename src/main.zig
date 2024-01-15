const std = @import("std");
const Token = @import("token.zig").Token;
const Lexer = @import("lexer.zig").Lexer;

pub fn main() void {
    const string =
        \\let x = 5;
        \\let y = 10;
        \\let add = fn(x, y) {
        \\  x + y;
        \\};
        \\let result = add(x, y);
    ;
    var lexer = Lexer.init(string);
    while (true) {
        const token = lexer.nextToken() orelse return;
        std.debug.print("{?}\n", .{token});
    }
}
