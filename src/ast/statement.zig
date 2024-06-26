const std = @import("std");
const Allocator = std.mem.Allocator;

const ast = @import("../ast.zig");

pub const Statement = union(enum) {
    block: BlockStatement,
    let: LetStatement,
    return_: ReturnStatement,
    while_: WhileStatement,
    expression: ast.Expression,

    pub fn deinit(self: *Statement, allocator: Allocator) void {
        switch (self.*) {
            .block => |*b| b.deinit(allocator),
            .let => |*l| l.deinit(allocator),
            .return_ => |*r| r.deinit(allocator),
            .while_ => |*w| w.deinit(allocator),
            .expression => |*e| e.deinit(allocator),
        }
    }

    pub fn write(self: Statement, writer: anytype) @TypeOf(writer).Error!void {
        switch (self) {
            .block => |b| try b.write(writer),
            .let => |l| try l.write(writer),
            .return_ => |r| try r.write(writer),
            .while_ => |w| try w.write(writer),
            .expression => |e| try e.write(writer, .lowest),
        }
    }
};

pub const BlockStatement = struct {
    statements: []Statement,

    pub fn deinit(self: *BlockStatement, allocator: Allocator) void {
        for (self.statements) |*statement| {
            statement.deinit(allocator);
        }
        allocator.free(self.statements);
    }

    pub fn write(self: BlockStatement, writer: anytype) !void {
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
    declare: bool,

    pub fn deinit(self: *LetStatement, allocator: Allocator) void {
        self.expression.deinit(allocator);
    }

    pub fn write(self: LetStatement, writer: anytype) !void {
        try writer.print("let ", .{});
        try self.identifier.write(writer);
        try writer.print(" = ", .{});
        try self.expression.write(writer, .lowest);
        try writer.print(";", .{});
    }
};

pub const ReturnStatement = struct {
    expression: ast.Expression,

    pub fn deinit(self: *ReturnStatement, allocator: Allocator) void {
        self.expression.deinit(allocator);
    }

    pub fn write(self: ReturnStatement, writer: anytype) !void {
        try writer.print("return ", .{});
        try self.expression.write(writer, .lowest);
        try writer.print(";", .{});
    }
};

pub const WhileStatement = struct {
    condition: ast.Expression,
    body: *Statement,

    pub fn deinit(self: *WhileStatement, allocator: Allocator) void {
        self.condition.deinit(allocator);
        self.body.deinit(allocator);
        allocator.destroy(self.body);
    }

    pub fn write(self: WhileStatement, writer: anytype) !void {
        try writer.print("while ", .{});
        try self.condition.write(writer);
        try writer.print(" ", .{});
        try self.body.write(writer);
    }
};
