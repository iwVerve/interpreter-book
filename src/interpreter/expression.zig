const Expression = @import("../ast.zig").Expression;
const Object = @import("object.zig").Object;

const IntegerLiteral = @import("../ast.zig").IntegerLiteral;
const BooleanLiteral = @import("../ast.zig").BooleanLiteral;

const InterpreterErrors = @import("error.zig").InterpreterErrors;

pub fn eval(expression: Expression) InterpreterErrors!Object {
    switch (expression) {
        .integer_literal => return evalIntegerLiteral(expression.integer_literal),
        .boolean_literal => return evalBooleanLiteral(expression.boolean_literal),
        else => return .null,
    }
}

fn evalIntegerLiteral(integer_literal: IntegerLiteral) Object {
    return .{ .integer = .{ .value = integer_literal.value } };
}

fn evalBooleanLiteral(boolean_literal: BooleanLiteral) Object {
    return .{ .bool = .{ .value = boolean_literal.value } };
}
