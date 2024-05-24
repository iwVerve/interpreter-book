const Parser = @import("../parser.zig").Parser;
const Ast = @import("../ast.zig");

pub fn parseIdentifier(self: *Parser) !Ast.Expression {
    const token = self.next() orelse return error.SuddenEOF;
    if (token != .identifier) {
        return error.ExpectedIdentifier;
    }
    return .{ .identifier = .{ .name = token.identifier } };
}
