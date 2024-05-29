const std = @import("std");
const ArrayList = std.ArrayList;

const ast = @import("../ast.zig");
const Config = @import("../Config.zig");

const Interpreter = @import("../interpreter.zig").Interpreter;
const Environment = @import("../interpreter/environment.zig").Environment;

const ValueImpl = @import("value.zig");
const Value = ValueImpl.Value;
const Builtin = ValueImpl.Builtin;

pub fn initializeBuiltins(environment: *Environment) !void {
    try environment.set("len", .{ .builtin = Builtin.len });
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

pub fn evalBuiltinCall(self: *Interpreter, builtin: Builtin, call: ast.CallExpression, environment: *Environment) !Value {
    if (builtin == .len and call.arguments.len != 1) {
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
    };
}
