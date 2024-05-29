const std = @import("std");
const Allocator = std.mem.Allocator;

const Config = @import("Config.zig");

const ast = @import("ast.zig");
const ValueImpl = @import("interpreter/value.zig");
const Value = ValueImpl.Value;
const AllocatedValue = ValueImpl.AllocatedValue;
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

    root: *Environment = undefined,
    first_environment: ?*Environment = undefined,
    call_stack: std.ArrayList(*Environment) = undefined,

    first_allocated_value: ?*AllocatedValue = undefined,

    const StatementImpl = @import("interpreter/statement.zig");
    pub usingnamespace StatementImpl;

    const ExpressionImpl = @import("interpreter/expression.zig");
    pub usingnamespace ExpressionImpl;

    const BuiltinImpl = @import("interpreter/builtin.zig");
    pub const evalBuiltinCall = BuiltinImpl.evalBuiltinCall;

    pub fn init(allocator: Allocator) !Interpreter {
        const root = try allocator.create(Environment);
        errdefer allocator.destroy(root);
        if (Config.log_gc) {
            std.debug.print("GC root: {*}\n", .{root});
        }
        root.* = Environment.init(allocator, null);
        try BuiltinImpl.initializeBuiltins(root);

        var call_stack = std.ArrayList(*Environment).init(allocator);
        try call_stack.append(root);
        return .{ .allocator = allocator, .root = root, .first_environment = root, .call_stack = call_stack };
    }

    pub fn deinit(self: *Interpreter) void {
        var environment = self.first_environment;
        while (environment != null) {
            const next = environment.?.next;
            environment.?.deinit();
            environment = next;
        }
        var value = self.first_allocated_value;
        while (value != null) {
            const next = value.?.next;
            value.?.deinit(self.allocator);
            value = next;
        }
        self.call_stack.deinit();
    }

    pub fn eval(self: *Interpreter, program: ast.Statement) !Value {
        self.return_state = .none;
        return try self.evalStatement(program, self.root);
    }

    pub fn append_environment(self: *Interpreter, environment: *Environment) void {
        environment.next = self.first_environment;
        self.first_environment = environment;
    }

    pub fn append_value(self: *Interpreter, value: *AllocatedValue) void {
        value.next = self.first_allocated_value;
        self.first_allocated_value = value;
    }

    pub fn gc(self: *Interpreter, current_environment: *Environment, current_return: ?*Value) void {
        if (Config.log_gc) {
            std.debug.print("GC start current: {*}\n", .{current_environment});
        }

        var environment = self.first_environment;
        while (environment != null) {
            environment.?.unmark();
            environment = environment.?.next;
        }

        var value = self.first_allocated_value;
        while (value != null) {
            value.?.unmark();
            value = value.?.next;
        }

        for (self.call_stack.items) |stack_environment| {
            stack_environment.mark();
        }
        current_environment.mark();
        if (current_return) |value_ptr| {
            if (value_ptr.* == .allocated) {
                value_ptr.allocated.mark();
            }
        }

        environment = self.first_environment;
        var previous: ?*Environment = null;
        while (environment != null) {
            const next = environment.?.next;
            if (environment.?.marked) {
                previous = environment;
            } else {
                if (previous == null) {
                    self.first_environment = next;
                } else {
                    previous.?.next = next;
                }

                if (Config.log_gc) {
                    std.debug.print("GC collect env: {*}\n", .{environment.?});
                }
                environment.?.deinit();
            }
            environment = next;
        }

        value = self.first_allocated_value;
        var previous_value: ?*AllocatedValue = null;
        while (value != null) {
            const next = value.?.next;
            if (value.?.marked) {
                previous_value = value;
            } else {
                if (previous_value == null) {
                    self.first_allocated_value = next;
                } else {
                    previous_value.?.next = next;
                }

                if (Config.log_gc) {
                    std.debug.print("GC collect value: {*}\n", .{value.?});
                }
                value.?.deinit(self.allocator);
            }
            value = next;
        }

        if (Config.log_gc) {
            std.debug.print("GC end\n", .{});
        }
    }
};
