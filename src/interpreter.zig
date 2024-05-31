const std = @import("std");
const Allocator = std.mem.Allocator;

const Config = @import("Config.zig");
const ast = @import("ast.zig");

pub fn Interpreter(comptime WriterType: anytype) type {
    return struct {
        const Self = @This();

        const EnvironmentImpl = @import("interpreter/environment.zig").Impl(WriterType);
        pub usingnamespace EnvironmentImpl;
        const Environment = EnvironmentImpl.Environment;

        const ValueImpl = @import("interpreter/value.zig").Impl(WriterType);
        pub usingnamespace ValueImpl;
        const Value = ValueImpl.Value;
        const AllocatedValue = ValueImpl.AllocatedValue;

        const StatementImpl = @import("interpreter/statement.zig").Impl(WriterType);
        pub usingnamespace StatementImpl;

        const ExpressionImpl = @import("interpreter/expression.zig").Impl(WriterType);
        pub usingnamespace ExpressionImpl;

        const BuiltinImpl = @import("interpreter/builtin.zig").Impl(WriterType);
        pub usingnamespace BuiltinImpl;

        pub const InterpreterError = error{
            TypeError,
            InvalidOperator,
            DivisionByZero,
            ValueNotFound,
            WrongNumberOfArguments,

            StreamTooLong,
        } || Allocator.Error || WriterType.Error || std.fs.File.OpenError || std.fs.File.ReadError;

        const ReturnState = union(enum) {
            none,
            function,
        };

        allocator: Allocator,
        writer: WriterType,
        working_directory: []const u8,
        return_state: ReturnState = .none,

        root: *Environment,
        first_environment: ?*Environment,
        call_stack: std.ArrayList(*Environment),

        first_allocated_value: ?*AllocatedValue = null,
        allocations_since_gc: u32 = 0,

        pub fn init(allocator: Allocator, writer: WriterType, working_directory: []const u8) !Self {
            const root = try allocator.create(Environment);
            errdefer allocator.destroy(root);
            if (Config.log_gc) {
                std.debug.print("GC root: {*}\n", .{root});
            }
            root.* = Environment.init(allocator, null);

            var call_stack = std.ArrayList(*Environment).init(allocator);
            try call_stack.append(root);
            return .{
                .allocator = allocator,
                .writer = writer,
                .working_directory = working_directory,
                .root = root,
                .first_environment = root,
                .call_stack = call_stack,
            };
        }

        pub fn deinit(self: *Self) void {
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

        pub fn eval(self: *Self, program: ast.Statement) !Value {
            self.return_state = .none;
            return try self.evalStatement(program, self.root);
        }

        pub fn append_environment(self: *Self, environment: *Environment) void {
            environment.next = self.first_environment;
            self.first_environment = environment;
        }

        pub fn append_value(self: *Self, value: *AllocatedValue) void {
            value.next = self.first_allocated_value;
            self.first_allocated_value = value;
        }

        pub fn gc(self: *Self, current_environment: *Environment, current_return: ?*Value) void {
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

            self.allocations_since_gc = 0;
            if (Config.log_gc) {
                std.debug.print("GC end\n", .{});
            }
        }
    };
}
