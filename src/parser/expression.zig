const Parser = @import("../parser.zig").Parser;
const Ast = @import("../ast.zig");

pub fn parseIdentifier(self: *Parser) !Ast.Expression {
    const token = self.next() orelse return error.SuddenEOF;
    if (token != .identifier) {
        return error.ExpectedIdentifier;
    }
    return .{ .identifier = .{ .name = token.identifier } };
}

pub fn parseInteger(self: *Parser) !Ast.Expression {
    const token = self.next() orelse return error.SuddenEOF;
    if (token != .integer) {
        return error.ExpectedInteger;
    }
    return .{ .integer = token.integer };
}

pub fn parseExpression(self: *Parser) !Ast.Expression {
    return try self.parseInteger();
}
