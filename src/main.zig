const std = @import("std");
const Token = @import("token.zig").Token;
const Lexer = @import("lexer.zig").Lexer;
const Parser = @import("parser.zig").Parser;
const SerializeOptions = @import("serialize.zig").SerializeOptions;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub const std_options = struct {
    pub const fmt_max_depth = 10;
};

pub fn main() !void {
    const string =
        \\let foo = bar;
    ;
    const statements = try Parser.parse(allocator, string);
    var options = SerializeOptions{
        .allocator = allocator,
        .debug = false,
    };
    for (statements.items) |statement| {
        std.debug.print("{s}\n", .{try statement.serialize(&options)});
    }
}
