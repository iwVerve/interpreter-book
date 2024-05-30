const Interpreter = @import("../interpreter.zig").Interpreter;

const std = @import("std");
const ArrayList = std.ArrayList;

const ast = @import("../ast.zig");
const Config = @import("../Config.zig");

pub fn Impl(comptime WriterType: anytype) type {
    const Self = Interpreter(WriterType);

    return struct {
        const Environment = Self.Environment;
        const Value = Self.Value;
        const AllocatedValue = Self.AllocatedValue;

        pub const Builtin = union(enum) {
            len,
            print,
            string,
        };

        pub fn evalBuiltin(expression: ast.Builtin) !Value {
            const type_info = @typeInfo(Builtin);
            const tag_type = type_info.Union.tag_type.?;
            const tag_type_info = @typeInfo(tag_type);

            const fields = tag_type_info.Enum.fields;
            inline for (fields) |field| {
                if (std.mem.eql(u8, expression.name, field.name)) {
                    const result: tag_type = @enumFromInt(field.value);
                    return .{ .builtin = result };
                }
            }

            return error.ValueNotFound;
        }

        fn builtinLen(value: Value) !Value {
            if (value != .allocated) {
                return error.TypeError;
            }
            if (value.allocated.value != .string) {
                return error.TypeError;
            }

            const length: Config.integer_type = @intCast(value.allocated.value.string.len);
            return .{ .integer = length };
        }

        fn builtinPrint(self: *Self, values: []Value) !Value {
            var first = true;

            for (values) |value| {
                if (first) {
                    first = false;
                } else {
                    try self.writer.print(" ", .{});
                }

                try value.write(self.writer);
            }

            try self.writer.print("\n", .{});
            return .null;
        }

        fn builtinString(self: *Self, value: Value) !Value {
            const string = try value.string(self);
            errdefer self.allocator.free(string);

            const allocated_value = try AllocatedValue.alloc(self);
            allocated_value.value.string = string;

            return .{ .allocated = allocated_value };
        }

        pub fn evalBuiltinCall(self: *Self, builtin: Builtin, call: ast.CallExpression, environment: *Environment) !Value {
            if (builtin == .len and call.arguments.len != 1) {
                return error.WrongNumberOfArguments;
            }
            if (builtin == .string and call.arguments.len != 1) {
                return error.WrongNumberOfArguments;
            }

            const call_environment = try self.allocator.create(Environment);
            call_environment.* = environment.extend();
            if (Config.log_gc) {
                std.debug.print("GC alloc env: {*}\n", .{call_environment});
            }
            self.append_environment(call_environment);

            try self.call_stack.append(call_environment);
            defer _ = self.call_stack.pop();

            var arguments = ArrayList(Value).init(self.allocator);
            defer arguments.deinit();

            for (call.arguments) |argument| {
                const value = try self.evalExpression(argument, environment);
                try arguments.append(value);
            }

            return switch (builtin) {
                .len => try builtinLen(arguments.items[0]),
                .print => try builtinPrint(self, arguments.items),
                .string => try builtinString(self, arguments.items[0]),
            };
        }
    };
}
