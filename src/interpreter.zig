const std = @import("std");
const Allocator = std.mem.Allocator;

const ast = @import("ast.zig");
const Value = @import("interpreter/value.zig").Value;
const Environment = @import("interpreter/environment.zig").Environment;

pub const InterpreterError = error{
    TypeError,
    InvalidOperator,
    DivisionByZero,
    ValueNotFound,
    WrongNumberOfArguments,

    OutOfMemory,
};

const ReturnState = union(enum) {
    none,
    function,
};

pub const Interpreter = struct {
    allocator: Allocator = undefined,
    return_state: ReturnState = undefined,
    root: Environment = undefined,

    const StatementImpl = @import("interpreter/statement.zig");
    pub usingnamespace StatementImpl;

    const ExpressionImpl = @import("interpreter/expression.zig");
    pub usingnamespace ExpressionImpl;

    pub fn init(allocator: Allocator) Interpreter {
        const root = Environment.init(allocator, null);
        return .{ .allocator = allocator, .root = root };
    }

    pub fn eval(self: *Interpreter, program: ast.Statement) !Value {
        self.return_state = .none;
        return try self.evalStatement(program, &self.root);
    }

    pub fn deinit(self: *Interpreter) void {
        self.root.deinit();
    }
};
