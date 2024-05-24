const std = @import("std");
const Allocator = std.mem.Allocator;

const ast = @import("../ast.zig");

pub const Statement = union(enum) {
    block: BlockStatement,
    let: LetStatement,

    pub fn deinit(self: *Statement, allocator: Allocator) void {
        switch (self) {
            .block => |b| b.deinit(allocator),
            .let => |l| l.deinit(allocator),
        }
    }
};

pub const BlockStatement = struct {
    statements: []Statement,

    pub fn deinit(self: *BlockStatement, allocator: Allocator) void {
        allocator.free(self.statements);
    }
};

pub const LetStatement = struct {
    identifier: ast.Identifier,
    expression: ast.Expression,

    pub fn deinit(self: *LetStatement, allocator: Allocator) void {
        self.identifier.deinit(allocator);
        self.expression.deinit(allocator);
    }
};
