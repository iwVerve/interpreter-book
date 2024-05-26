const std = @import("std");
const ArrayList = std.ArrayList;

const Parser = @import("../parser.zig").Parser;
const Ast = @import("../ast.zig");

pub fn parseLetStatement(self: *Parser) !Ast.Statement {
    try self.assertNext(.let);

    const identifier = try self.parseIdentifier();
    try self.expectNext(.assign);
    const expression = try self.parseExpression();

    return .{ .let = .{ .identifier = identifier.identifier, .expression = expression } };
}

pub fn parseStatement(self: *Parser) !?Ast.Statement {
    const token = self.peek() orelse return null;

    return switch (token) {
        .let => try self.parseLetStatement(),
        else => null,
    };
}

pub fn parseStatements(self: *Parser) !Ast.Statement {
    var statements = ArrayList(Ast.Statement).init(self.allocator);

    while (true) {
        const statement = try self.parseStatement() orelse break;
        try statements.append(statement);
    }

    const slice = try statements.toOwnedSlice();
    return .{ .block = .{ .statements = slice } };
}
