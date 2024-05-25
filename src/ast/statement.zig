const std = @import("std");
const Allocator = std.mem.Allocator;

const ast = @import("../ast.zig");

pub const Statement = union(enum) {
    block: BlockStatement,
    let: LetStatement,

    pub fn deinit(self: *Statement, allocator: Allocator) void {
        switch (self.*) {
            .block => |*b| b.deinit(allocator),
            .let => |*l| l.deinit(allocator),
        }
    }

    pub fn write(self: Statement, writer: anytype) @TypeOf(writer).Error!void {
        switch (self) {
            .block => |b| try b.write(writer),
            .let => |l| try l.write(writer),
        }
    }
};

pub const BlockStatement = struct {
    statements: []Statement,

    pub fn deinit(self: *BlockStatement, allocator: Allocator) void {
        allocator.free(self.statements);
    }

    pub fn write(self: BlockStatement, writer: anytype) @TypeOf(writer).Error!void {
        try writer.print("{{\n", .{});
        for (self.statements) |statement| {
            try statement.write(writer);
            try writer.print("\n", .{});
        }
        try writer.print("}}\n", .{});
    }
};

pub const LetStatement = struct {
    identifier: ast.Identifier,
    expression: ast.Expression,

    pub fn deinit(self: *LetStatement, allocator: Allocator) void {
        self.identifier.deinit(allocator);
        self.expression.deinit(allocator);
    }

    pub fn write(self: LetStatement, writer: anytype) @TypeOf(writer).Error!void {
        try writer.print("let ", .{});
        try self.identifier.write(writer);
        try writer.print(" = ", .{});
        try self.expression.write(writer);
        try writer.print(";", .{});
    }
};
