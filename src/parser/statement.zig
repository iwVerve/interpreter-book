const std = @import("std");
const ArrayList = std.ArrayList;

const Parser = @import("../parser.zig").Parser;
const Ast = @import("../ast.zig");

pub fn parseLetStatement(self: *Parser) !Ast.Statement {
    self.assertNext(.let);

    const identifier = try self.parseIdentifier();
    try self.expectNext(.assign);
    var expression = try self.parseExpression();
    errdefer expression.deinit(self.allocator);
    try self.expectNext(.semicolon);

    return .{ .let = .{ .identifier = identifier.identifier, .expression = expression } };
}

pub fn parseReturnStatement(self: *Parser) !Ast.Statement {
    self.assertNext(.return_);

    const expression = try self.parseExpression();
    try self.expectNext(.semicolon);

    return .{ .return_ = .{ .expression = expression } };
}

pub fn parseStatement(self: *Parser) !?Ast.Statement {
    const token = self.peek() orelse return null;

    return switch (token) {
        .let => try self.parseLetStatement(),
        .return_ => try self.parseReturnStatement(),
        else => error.UnexpectedToken,
    };
}

pub fn parseStatements(self: *Parser) !Ast.Statement {
    var statements = ArrayList(Ast.Statement).init(self.allocator);
    errdefer {
        for (statements.items) |*statement| {
            statement.deinit(self.allocator);
        }
        statements.deinit();
    }

    while (true) {
        const statement = try self.parseStatement() orelse break;
        try statements.append(statement);
    }

    const slice = try statements.toOwnedSlice();
    return .{ .block = .{ .statements = slice } };
}
