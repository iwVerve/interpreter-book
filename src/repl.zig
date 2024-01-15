const std = @import("std");
const File = std.fs.File;
const Lexer = @import("lexer.zig").Lexer;

pub fn start() !void {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    var buf: [1024]u8 = undefined;

    if (try stdin.readUntilDelimiterOrEof(buf[0..], '\n')) |input| {
        try stdout.print("{s}", .{input});
    }
}
