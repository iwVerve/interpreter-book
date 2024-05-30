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
            char_at,
        };

        const BuiltinData = .{
            .{ .len, "len" },
            .{ .print, "print" },
            .{ .string, "string" },
            .{ .char_at, "charAt" },
        };

        pub fn evalBuiltin(expression: ast.Builtin) !Value {
            inline for (BuiltinData) |builtin| {
                if (std.mem.eql(u8, expression.name, builtin[1])) {
                    return .{ .builtin = builtin[0] };
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

        fn builtinCharAt(self: *Self, value: Value, position_value: Value) !Value {
            if (value != .allocated) {
                return error.TypeError;
            }
            if (value.allocated.value != .string) {
                return error.TypeError;
            }
            if (position_value != .integer) {
                return error.TypeError;
            }

            const source = value.allocated.value.string;
            const position = position_value.integer;

            if (position < 0 or position >= source.len) {
                return .null;
            }

            const string = try self.allocator.alloc(u8, 1);
            @memcpy(string, source.ptr + @as(usize, @intCast(position)));

            const allocated_value = try AllocatedValue.alloc(self);
            allocated_value.value.string = string;

            return .{ .allocated = allocated_value };
        }

        pub fn evalBuiltinCall(self: *Self, builtin: Builtin, call: ast.CallExpression, environment: *Environment) !Value {
            if (call.arguments.len != 1) {
                if (builtin == .len or builtin == .string) {
                    return error.WrongNumberOfArguments;
                }
            }
            if (call.arguments.len != 2) {
                if (builtin == .char_at) {
                    return error.WrongNumberOfArguments;
                }
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
                .char_at => try builtinCharAt(self, arguments.items[0], arguments.items[1]),
            };
        }
    };
}
