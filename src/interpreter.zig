const std = @import("std");
const Allocator = std.mem.Allocator;

const Config = @import("Config.zig");

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
    root: *Environment = undefined,
    first_environment: ?*Environment = undefined,
    call_stack: std.ArrayList(*Environment) = undefined,

    const StatementImpl = @import("interpreter/statement.zig");
    pub usingnamespace StatementImpl;

    const ExpressionImpl = @import("interpreter/expression.zig");
    pub usingnamespace ExpressionImpl;

    pub fn init(allocator: Allocator) !Interpreter {
        const root = try allocator.create(Environment);
        errdefer allocator.destroy(root);
        if (Config.log_gc) {
            std.debug.print("GC root: {*}\n", .{root});
        }
        root.* = Environment.init(allocator, null);

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

    pub fn gc(self: *Interpreter, current_environment: *Environment) void {
        if (Config.log_gc) {
            std.debug.print("GC START current: {*}\n", .{current_environment});
        }

        var environment = self.first_environment;
        while (environment != null) {
            environment.?.unmark();
            environment = environment.?.next;
        }

        for (self.call_stack.items) |stack_environment| {
            stack_environment.mark();
        }
        current_environment.mark();

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
                    std.debug.print("GC COLLECT env: {*}\n", .{environment.?});
                }
                environment.?.deinit();
            }
            environment = next;
        }
    }
};
