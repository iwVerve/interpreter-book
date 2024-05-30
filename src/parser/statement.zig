const std = @import("std");
const ArrayList = std.ArrayList;

const Parser = @import("../parser.zig").Parser;
const Ast = @import("../ast.zig");

const ParseStatementError = error{
    SuddenEOF,
    UnexpectedToken,
    ExpectedIdentifier,

    OutOfMemory,
};

pub fn parseLetStatement(self: *Parser) !Ast.Statement {
    self.assertNext(.let);

    const identifier = try self.parseIdentifier();
    try self.expectNext(.assign);
    var expression = try self.parseExpression();
    errdefer expression.deinit(self.allocator);
    try self.expectNext(.semicolon);

    return .{ .let = .{ .identifier = identifier.identifier, .expression = expression, .declare = true } };
}

pub fn maybeParseAssignStatement(self: *Parser) !Ast.Statement {
    self.advance();

    const peek = self.peek();
    self.position -= 1;
    if (peek == null or peek.? != .assign) {
        return try self.parseExpressionStatement();
    }

    const identifier = try self.parseIdentifier();
    self.assertNext(.assign);
    var expression = try self.parseExpression();
    errdefer expression.deinit(self.allocator);
    try self.expectNext(.semicolon);

    return .{ .let = .{ .identifier = identifier.identifier, .expression = expression, .declare = false } };
}

pub fn parseReturnStatement(self: *Parser) !Ast.Statement {
    self.assertNext(.return_);

    const expression = try self.parseExpression();
    try self.expectNext(.semicolon);

    return .{ .return_ = .{ .expression = expression } };
}

pub fn parseGroupedStatements(self: *Parser) !Ast.Statement {
    self.assertNext(.brace_l);

    var statements = try self.parseStatements();
    errdefer statements.deinit(self.allocator);
    try self.expectNext(.brace_r);

    return statements;
}

pub fn parseExpressionStatement(self: *Parser) !Ast.Statement {
    const expression = try self.parseExpression();

    const peek = self.peek();
    if (peek != null and peek.? == .semicolon) {
        self.advance();
    }

    return .{ .expression = expression };
}

pub fn parseStatement(self: *Parser) ParseStatementError!?Ast.Statement {
    const token = self.peek() orelse return null;

    return switch (token) {
        .let => try self.parseLetStatement(),
        .identifier => try self.maybeParseAssignStatement(),
        .return_ => try self.parseReturnStatement(),
        .brace_l => try self.parseGroupedStatements(),
        .brace_r => null,
        else => try self.parseExpressionStatement(),
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
