const std = @import("std");

const Config = @import("../Config.zig");

const InterpreterImpl = @import("../interpreter.zig");
const Interpreter = InterpreterImpl.Interpreter;
const InterpreterError = InterpreterImpl.InterpreterError;

const ast = @import("../ast.zig");
const ValueImpl = @import("value.zig");
const Value = ValueImpl.Value;
const AllocatedValue = ValueImpl.AllocatedValue;
const Environment = @import("environment.zig").Environment;

pub fn evalBinaryExpression(self: anytype, expression: ast.BinaryExpression, environment: *Environment) !Value {
    const left = try self.evalExpression(expression.left.*, environment);
    const right = try self.evalExpression(expression.right.*, environment);

    return switch (expression.operator) {
        .plus => try Value.add(self, left, right),
        .minus => try Value.subtract(left, right),
        .asterisk => try Value.multiply(left, right),
        .slash => try Value.divide(left, right),

        .equal => try Value.equal(left, right),
        .not_equal => try Value.not_equal(left, right),
        .greater_than => try Value.greater_than(left, right),
        .less_than => try Value.less_than(left, right),
        else => error.InvalidOperator,
    };
}

pub fn evalUnaryExpression(self: anytype, expression: ast.UnaryExpression, environment: *Environment) !Value {
    const value = try self.evalExpression(expression.expression.*, environment);

    return switch (expression.operator) {
        .plus => value,
        .minus => try Value.negateInteger(value),
        .bang => try Value.negateBool(value),
        else => error.InvalidOperator,
    };
}

pub fn evalIfExpression(self: anytype, expression: ast.IfExpression, environment: *Environment) !Value {
    const condition = try self.evalExpression(expression.condition.*, environment);

    if (Value.isTruthy(condition)) {
        return try self.evalStatement(expression.then.*, environment);
    } else if (expression.else_) |else_statement| {
        return try self.evalStatement(else_statement.*, environment);
    }
    return Value.null;
}

pub fn evalFunctionLiteral(self: anytype, function: ast.FunctionExpression, environment: *Environment) !Value {
    _ = self;
    return .{ .function = .{
        .parameters = function.parameters,
        .body = function.body,
        .environment = environment,
    } };
}

pub fn evalFunctionCall(self: anytype, call: ast.CallExpression, environment: *Environment) !Value {
    const function_value = try self.evalExpression(call.function.*, environment);
    if (function_value == .builtin) {
        return try self.evalBuiltinCall(function_value.builtin, call, environment);
    }
    if (function_value != .function) {
        return error.TypeError;
    }
    var function = function_value.function;

    if (call.arguments.len != function.parameters.len) {
        return error.WrongNumberOfArguments;
    }

    const call_environment = try self.allocator.create(Environment);
    call_environment.* = function.environment.extend();
    if (Config.log_gc) {
        std.debug.print("GC alloc env: {*}\n", .{call_environment});
    }
    self.append_environment(call_environment);
    try self.call_stack.append(call_environment);

    for (0..call.arguments.len) |i| {
        const name = function.parameters[i];
        const value = try self.evalExpression(call.arguments[i], environment);
        try call_environment.set(name, value);
    }

    const result = try self.evalStatement(function.body.*, call_environment);
    _ = self.call_stack.pop();

    if (self.return_state == .function) {
        self.return_state = .none;
    }
    return result;
}

pub fn evalIdentifier(expression: ast.Identifier, environment: Environment) !Value {
    return environment.get(expression.name) orelse error.ValueNotFound;
}

pub fn evalStringLiteral(self: anytype, string: []const u8) !Value {
    const allocated_value = try AllocatedValue.alloc(self);
    allocated_value.* = .{ .value = .{ .string = try self.allocator.dupe(u8, string) } };
    return .{ .allocated = allocated_value };
}

pub fn evalExpression(self: anytype, expression: ast.Expression, environment: *Environment) InterpreterError!Value {
    return switch (expression) {
        .binary => |b| try self.evalBinaryExpression(b, environment),
        .unary => |u| try self.evalUnaryExpression(u, environment),
        .if_ => |i| try self.evalIfExpression(i, environment),
        .function => |f| try self.evalFunctionLiteral(f, environment),
        .call => |c| try self.evalFunctionCall(c, environment),
        .identifier => |i| try evalIdentifier(i, environment.*),
        .string => |s| try evalStringLiteral(self, s),
        .bool => |b| .{ .bool = b },
        .integer => |i| .{ .integer = i },
    };
}
