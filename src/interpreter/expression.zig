const InterpreterImpl = @import("../interpreter.zig");
const Interpreter = InterpreterImpl.Interpreter;
const InterpreterError = InterpreterImpl.InterpreterError;

const ast = @import("../ast.zig");
const Value = @import("value.zig").Value;

pub fn evalBinaryExpression(self: *Interpreter, expression: ast.BinaryExpression) !Value {
    const left = try self.evalExpression(expression.left.*);
    const right = try self.evalExpression(expression.right.*);

    return switch (expression.operator) {
        .plus => try Value.add(left, right),
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

pub fn evalUnaryExpression(self: *Interpreter, expression: ast.UnaryExpression) !Value {
    const value = try self.evalExpression(expression.expression.*);

    return switch (expression.operator) {
        .plus => value,
        .minus => try Value.negateInteger(value),
        .bang => try Value.negateBool(value),
        else => error.InvalidOperator,
    };
}

pub fn evalIfExpression(self: *Interpreter, expression: ast.IfExpression) !Value {
    const condition = try self.evalExpression(expression.condition.*);

    if (Value.isTruthy(condition)) {
        return try self.evalStatement(expression.then.*);
    } else if (expression.else_) |else_statement| {
        return try self.evalStatement(else_statement.*);
    }
    return Value.null;
}

pub fn evalIdentifier(self: Interpreter, expression: ast.Identifier) !Value {
    return self.root.get(expression.name) orelse error.ValueNotFound;
}

pub fn evalExpression(self: *Interpreter, expression: ast.Expression) InterpreterError!Value {
    return switch (expression) {
        .binary => |b| try self.evalBinaryExpression(b),
        .unary => |u| try self.evalUnaryExpression(u),
        .if_ => |i| try self.evalIfExpression(i),
        .identifier => |i| try self.evalIdentifier(i),
        .bool => |b| .{ .bool = b },
        .integer => |i| .{ .integer = i },
        else => @panic("todo"),
    };
}
