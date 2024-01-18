const std = @import("std");
const ArrayList = std.ArrayList;

const Expression = @import("../ast.zig").Expression;
const Identifier = @import("../ast.zig").Identifier;

const SerializeOptions = @import("../serialize.zig").SerializeOptions;

pub const Statement = union(enum) {
    let: LetStatement,
    return_: ReturnStatement,
    expression: Expression,
    block: BlockStatement,

    pub fn serialize(self: Statement, options: *SerializeOptions) ![]const u8 {
        return try std.fmt.allocPrint(options.allocator, "{s}", .{try switch (self) {
            .let => self.let.serialize(options),
            .return_ => self.return_.serialize(options),
            .expression => self.expression.serialize(options),
            .block => self.block.serialize(options),
        }});
    }
};

pub const BlockStatement = struct {
    statements: ArrayList(Statement),

    pub fn serialize(self: BlockStatement, options: *SerializeOptions) ![]const u8 {
        _ = self;
        const out = try options.allocator.create([]u8);
        out.* = "";
        return out.*;
    }
};

pub const LetStatement = struct {
    identifier: Identifier,
    expression: Expression,

    pub fn serialize(self: LetStatement, options: *SerializeOptions) ![]const u8 {
        return try std.fmt.allocPrint(options.allocator, "let {s} = {s};", .{ try self.identifier.serialize(options), try self.expression.serialize(options) });
    }
};

pub const ReturnStatement = struct {
    expression: Expression,

    pub fn serialize(self: ReturnStatement, options: *SerializeOptions) ![]const u8 {
        return try std.fmt.allocPrint(options.allocator, "return {s};", .{try self.expression.serialize(options)});
    }
};
