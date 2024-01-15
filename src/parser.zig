const ast = @import("ast.zig");
const Lexer = @import("lexer.zig").Lexer;

pub fn parse(source: []const u8) ast.Node {
    var lexer = Lexer{ .source = source };
    _ = lexer;
}

test "parser" {
    const source = "let x = 5;";
    const program = parse(source);
    _ = program;
}
