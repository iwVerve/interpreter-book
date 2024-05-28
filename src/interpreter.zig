const std = @import("std");
const Allocator = std.mem.Allocator;

const ast = @import("ast.zig");
const Value = @import("interpreter/value.zig").Value;

pub const InterpreterError = error{
    TypeError,
    InvalidOperator,
};

const ReturnState = union(enum) {
    none,
    function,
};

pub const Interpreter = struct {
    allocator: Allocator,
    return_state: ReturnState = undefined,

    const StatementImpl = @import("interpreter/statement.zig");
    pub usingnamespace StatementImpl;

    const ExpressionImpl = @import("interpreter/expression.zig");
    pub usingnamespace ExpressionImpl;

    pub fn eval(self: *Interpreter, program: ast.Statement) !Value {
        self.return_state = .none;
        return try self.evalStatement(program);
    }

    pub fn deinit(self: *Interpreter) void {
        _ = self;
    }
};
