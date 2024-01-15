const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;
const Token = @import("token.zig").Token;

pub fn start() !void {
    var buffered_reader = std.io.bufferedReader(std.io.getStdIn().reader());
    const reader = buffered_reader.reader();
    const writer = std.io.getStdOut().writer();

    while (true) {
        var buffer: [1024]u8 = undefined;
        const input = try reader.readUntilDelimiterOrEof(&buffer, '\n') orelse {
            return;
        };

        var lexer = Lexer{ .source = input };
        while (true) {
            const token = lexer.nextToken();
            try writer.print("{}\n", .{token});
            if (token == Token.eof) {
                break;
            }
        }
    }
}
