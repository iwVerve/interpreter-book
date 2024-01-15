const std = @import("std");
const Token = @import("token.zig").Token;
const Lexer = @import("lexer.zig").Lexer;

pub fn main() void {
    const string =
        \\if (a == b) {}
    ;
    var lexer = Lexer.init(string);
    while (true) {
        const token = lexer.nextToken() orelse return;
        std.debug.print("{?}\n", .{token});
    }
}
