const std = @import("std");
const ArrayList = std.ArrayList;

const Expression = @import("../ast.zig").Expression;
const Identifier = @import("../ast.zig").Identifier;

const SerializeOptions = @import("serialize.zig").SerializeOptions;
const SerializeErrors = @import("serialize.zig").SerializeErrors;

pub const Statement = union(enum) {
    let: LetStatement,
    return_: ReturnStatement,
    expression: Expression,
    block: BlockStatement,

    pub fn write(self: Statement, writer: anytype, options: *SerializeOptions) SerializeErrors!void {
        switch (self) {
            .let => try self.let.write(writer, options),
            .return_ => try self.return_.write(writer, options),
            .expression => {
                try self.expression.write(writer, options, .lowest);
                _ = try writer.write("\n");
            },
            .block => try self.block.write(writer, options),
        }
    }
};

pub const BlockStatement = struct {
    statements: ArrayList(Statement),

    pub fn write(self: BlockStatement, writer: anytype, options: *SerializeOptions) !void {
        if (!options.top_level) {
            options.indent += 1;
            try writer.print("{{\n", .{});
        }
        const top_level = options.top_level;
        options.top_level = false;
        for (self.statements.items) |statement| {
            try writer.writeByteNTimes(' ', 4 * options.indent);
            try statement.write(writer, options);
        }
        options.top_level = top_level;
        if (!options.top_level) {
            options.indent -= 1;
            try writer.writeByteNTimes(' ', 4 * options.indent);
            try writer.print("}}", .{});
        }
    }
};

pub const LetStatement = struct {
    identifier: Identifier,
    expression: Expression,

    pub fn write(self: LetStatement, writer: anytype, options: *SerializeOptions) !void {
        _ = try writer.write("let ");
        try self.identifier.write(writer, options);
        _ = try writer.write(" = ");
        try self.expression.write(writer, options, .lowest);
        _ = try writer.write(";\n");
    }
};

pub const ReturnStatement = struct {
    expression: Expression,

    pub fn write(self: ReturnStatement, writer: anytype, options: *SerializeOptions) !void {
        _ = try writer.write("return ");
        try self.expression.write(writer, options, .lowest);
        _ = try writer.write(";\n");
    }
};
