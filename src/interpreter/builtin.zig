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
            file,
            read_line,
        };

        const BuiltinData = .{
            .{ .len, "len" },
            .{ .print, "print" },
            .{ .string, "string" },
            .{ .char_at, "charAt" },
            .{ .file, "file" },
            .{ .read_line, "readLine" },
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

        fn builtinFile(self: *Self, value: Value) !Value {
            if (value != .allocated and value.allocated.value != .string) {
                return error.TypeError;
            }
            const string = value.allocated.value.string;

            const paths = [_][]const u8{ self.working_directory, string };
            const full_path = try std.fs.path.join(self.allocator, &paths);
            defer self.allocator.free(full_path);

            const file = try std.fs.openFileAbsolute(full_path, .{});
            errdefer file.close();

            const allocated_value = try AllocatedValue.alloc(self);
            errdefer allocated_value.deinit(self.allocator);
            allocated_value.value = .{ .file = file };

            return .{ .allocated = allocated_value };
        }

        fn builtinReadLine(self: *Self, value: Value) !Value {
            if (value != .allocated and value.allocated.value != .file) {
                return error.TypeError;
            }
            const file = value.allocated.value.file;
            const reader = file.reader();
            const line = try reader.readUntilDelimiterOrEofAlloc(self.allocator, '\n', 1024);
            if (line == null) {
                return .null;
            }
            errdefer self.allocator.free(line.?);

            const string = try AllocatedValue.alloc(self);
            errdefer string.deinit(self.allocator);
            string.value = .{ .string = line.? };

            return .{ .allocated = string };
        }

        pub fn evalBuiltinCall(self: *Self, builtin: Builtin, call: ast.CallExpression, environment: *Environment) !Value {
            if (call.arguments.len != 1) {
                switch (builtin) {
                    .len, .string, .file, .read_line => return error.WrongNumberOfArguments,
                    else => {},
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

            const args = arguments.items;
            return switch (builtin) {
                .len => try builtinLen(args[0]),
                .print => try builtinPrint(self, args),
                .string => try builtinString(self, args[0]),
                .char_at => try builtinCharAt(self, args[0], args[1]),
                .file => try builtinFile(self, args[0]),
                .read_line => try builtinReadLine(self, args[0]),
            };
        }
    };
}
