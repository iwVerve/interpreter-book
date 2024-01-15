const std = @import("std");
const ArrayList = std.ArrayList;
const Token = @import("token.zig").Token;

pub const Node = union(enum) {
    program: Program,
    statement: Statement,
    expression,
};

const Program = struct {
    allocator: std.mem.Allocator = undefined,
    statements: ArrayList(Statement) = undefined,

    pub fn init(self: *Program, allocator: std.mem.Allocator) void {
        self.allocator = allocator;
        self.statements.init(allocator);
    }

    pub fn deinit(self: *Program) void {
        self.statements.deinit();
    }
};

const Statement = union(enum) {
    let: Let,
};

const Let = struct {
    token: *Token,
    name: *Identifier,

    pub fn name(self: Let) []const u8 {
        return self.name.value();
    }
};

const Identifier = struct {
    token: *Token,

    pub fn value(self: Identifier) []const u8 {
        return self.token.identifier;
    }
};

test "ast" {
    _ = Program{};
}
