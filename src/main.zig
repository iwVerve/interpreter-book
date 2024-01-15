const std = @import("std");
const t = @import("token.zig");
const Lexer = @import("lexer.zig").Lexer;
const repl = @import("repl.zig");

pub fn main() !void {
    try repl.start();
}

test "simple token" {
    const input = "=+(){},;";
    var lexer = Lexer{ .source = input };

    try std.testing.expect(lexer.nextToken() == t.Token.assign);
    try std.testing.expect(lexer.nextToken() == t.Token.plus);
    try std.testing.expect(lexer.nextToken() == t.Token.paren_l);
    try std.testing.expect(lexer.nextToken() == t.Token.paren_r);
    try std.testing.expect(lexer.nextToken() == t.Token.curly_l);
    try std.testing.expect(lexer.nextToken() == t.Token.curly_r);
    try std.testing.expect(lexer.nextToken() == t.Token.comma);
    try std.testing.expect(lexer.nextToken() == t.Token.semicolon);
}

test "simple source" {
    const input =
        \\let five = 5;
        \\let ten = 10;
        \\
        \\let add = fn(x, y) {
        \\  x + y
        \\};
        \\
        \\let result = add(five, ten);
    ;
    var lexer = Lexer{ .source = input };

    try std.testing.expect(lexer.nextToken() == t.Token.let);
    try std.testing.expect(std.mem.eql(u8, lexer.nextToken().identifier, "five"));
    try std.testing.expect(lexer.nextToken() == t.Token.assign);
    try std.testing.expect(std.mem.eql(u8, lexer.nextToken().integer, "5"));
    try std.testing.expect(lexer.nextToken() == t.Token.semicolon);

    try std.testing.expect(lexer.nextToken() == t.Token.let);
    try std.testing.expect(std.mem.eql(u8, lexer.nextToken().identifier, "ten"));
    try std.testing.expect(lexer.nextToken() == t.Token.assign);
    try std.testing.expect(std.mem.eql(u8, lexer.nextToken().integer, "10"));
    try std.testing.expect(lexer.nextToken() == t.Token.semicolon);

    try std.testing.expect(lexer.nextToken() == t.Token.let);
    try std.testing.expect(std.mem.eql(u8, lexer.nextToken().identifier, "add"));
    try std.testing.expect(lexer.nextToken() == t.Token.assign);
    try std.testing.expect(lexer.nextToken() == t.Token.function);
    try std.testing.expect(lexer.nextToken() == t.Token.paren_l);
    try std.testing.expect(std.mem.eql(u8, lexer.nextToken().identifier, "x"));
    try std.testing.expect(lexer.nextToken() == t.Token.comma);
    try std.testing.expect(std.mem.eql(u8, lexer.nextToken().identifier, "y"));
    try std.testing.expect(lexer.nextToken() == t.Token.paren_r);
    try std.testing.expect(lexer.nextToken() == t.Token.curly_l);

    try std.testing.expect(std.mem.eql(u8, lexer.nextToken().identifier, "x"));
    try std.testing.expect(lexer.nextToken() == t.Token.plus);
    try std.testing.expect(std.mem.eql(u8, lexer.nextToken().identifier, "y"));

    try std.testing.expect(lexer.nextToken() == t.Token.curly_r);
    try std.testing.expect(lexer.nextToken() == t.Token.semicolon);

    try std.testing.expect(lexer.nextToken() == t.Token.let);
    try std.testing.expect(std.mem.eql(u8, lexer.nextToken().identifier, "result"));
    try std.testing.expect(lexer.nextToken() == t.Token.assign);
    try std.testing.expect(std.mem.eql(u8, lexer.nextToken().identifier, "add"));
    try std.testing.expect(lexer.nextToken() == t.Token.paren_l);
    try std.testing.expect(std.mem.eql(u8, lexer.nextToken().identifier, "five"));
    try std.testing.expect(lexer.nextToken() == t.Token.comma);
    try std.testing.expect(std.mem.eql(u8, lexer.nextToken().identifier, "ten"));
    try std.testing.expect(lexer.nextToken() == t.Token.paren_r);
}
