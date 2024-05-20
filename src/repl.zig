const std = @import("std");
const Parser = @import("parser.zig").Parser;
const StatementInterpreter = @import("interpreter.zig").StatementInterpreter;
const Environment = @import("interpreter.zig").Environment;

pub fn start(allocator: std.mem.Allocator) !void {
    const stdin = std.io.getStdIn().reader();
    var buf = std.io.bufferedReader(stdin);
    var reader = buf.reader();
    const writer = std.io.getStdOut().writer();

    var environment = Environment.init(allocator);
    defer environment.deinit();

    var lines = std.ArrayList([1024]u8).init(allocator);
    defer lines.deinit();

    while (true) {
        const line_buffer = try allocator.create([1024]u8);
        try lines.append(line_buffer.*);

        _ = try writer.write("~ ");
        const line = try reader.readUntilDelimiterOrEof(line_buffer, '\n') orelse continue;

        const program = try Parser.parse(allocator, line);
        const result = (try StatementInterpreter.evalBlockStatement(program, &environment)).unwrap();

        if (result != .null) {
            _ = try writer.write("> ");
            try result.write(writer);
            _ = try writer.write("\n");
        }
    }
}
