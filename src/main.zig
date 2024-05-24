const std = @import("std");

const Lexer = @import("lexer.zig").Lexer;
const ast = @import("ast.zig");

pub fn main() !void {
    const source =
        \\let five = 5;
        \\if (five < 10) {
        \\    return true;
        \\}
        \\else if (five == 5) {
        \\    return false;
        \\}
    ;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var lexer = Lexer{ .allocator = allocator };
    const tokens = try lexer.lex(source);
    defer tokens.deinit();

    const stdout = std.io.getStdOut();
    const writer = stdout.writer();

    for (tokens.items) |token| {
        try token.serialize(writer);
        _ = try writer.write("\n");
    }

    const str = try allocator.alloc(u8, 5);
    std.mem.copyForwards(u8, str, "hello");

    var a = ast.Expression{ .identifier = .{ .name = str } };
    defer a.deinit(allocator);
}
