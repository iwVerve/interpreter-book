const InterpreterImpl = @import("../interpreter.zig");
const Interpreter = InterpreterImpl.Interpreter;
const InterpreterError = InterpreterImpl.InterpreterError;

const ast = @import("../ast.zig");
const Value = @import("value.zig").Value;

pub fn evalBinaryExpression(self: Interpreter, expression: ast.BinaryExpression) !Value {
    const left = try self.evalExpression(expression.left.*);
    const right = try self.evalExpression(expression.right.*);

    return switch (expression.operator) {
        .plus => try Value.add(left, right),
        .minus => try Value.subtract(left, right),
        .asterisk => try Value.multiply(left, right),
        .slash => try Value.divide(left, right),
        else => error.InvalidOperator,
    };
}

pub fn evalUnaryExpression(self: Interpreter, expression: ast.UnaryExpression) !Value {
    const value = try self.evalExpression(expression.expression.*);

    return switch (expression.operator) {
        .plus => value,
        .minus => try Value.negateInteger(value),
        .bang => try Value.negateBool(value),
        else => error.InvalidOperator,
    };
}

pub fn evalExpression(self: Interpreter, expression: ast.Expression) InterpreterError!Value {
    return switch (expression) {
        .binary => |b| try self.evalBinaryExpression(b),
        .unary => |u| try self.evalUnaryExpression(u),
        .bool => |b| .{ .bool = b },
        .integer => |i| .{ .integer = i },
        else => @panic("todo"),
    };
}
