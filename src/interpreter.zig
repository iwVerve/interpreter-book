const std = @import("std");
const Allocator = std.mem.Allocator;

pub const InterpreterError = error{
    TypeError,
    InvalidOperator,
};

pub const Interpreter = struct {
    allocator: Allocator,

    const StatementImpl = @import("interpreter/statement.zig");
    pub usingnamespace StatementImpl;

    const ExpressionImpl = @import("interpreter/expression.zig");
    pub usingnamespace ExpressionImpl;

    pub fn deinit(self: *Interpreter) void {
        _ = self;
    }
};
