const std = @import("std");

const Lexer = @import("lexer.zig").Lexer;
const Parser = @import("parser.zig").Parser;
const Interpreter = @import("interpreter.zig").Interpreter;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const stdout = std.io.getStdOut();
    const stdout_writer = stdout.writer();
    if (args.len != 2) {
        try stdout_writer.print("Usage: monkey.exe [path]\n", .{});
        return;
    }

    const working_directory = try std.fs.cwd().realpathAlloc(allocator, "");
    defer allocator.free(working_directory);

    const paths = [_][]const u8{ working_directory, args[1] };
    const input_path = try std.fs.path.join(allocator, &paths);
    defer allocator.free(input_path);

    const source_file = try std.fs.openFileAbsolute(input_path, .{});
    defer source_file.close();

    const source = try source_file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(source);

    var lexer = Lexer{ .allocator = allocator };
    const tokens = try lexer.lex(source);
    defer {
        for (tokens) |*token| {
            token.deinit(allocator);
        }
        allocator.free(tokens);
    }

    var parser = Parser{ .allocator = allocator };
    var program = try parser.parse(tokens);
    defer program.deinit(allocator);

    var buffered_writer = std.io.bufferedWriter(stdout_writer);
    const writer = buffered_writer.writer();

    var interpreter = try Interpreter(@TypeOf(writer)).init(allocator, writer, working_directory);
    _ = try interpreter.eval(program);
    defer interpreter.deinit();

    try buffered_writer.flush();
}
