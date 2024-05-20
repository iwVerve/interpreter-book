const std = @import("std");
const ArrayList = std.ArrayList;

const Expression = @import("../ast.zig").Expression;
const Object = @import("object.zig").Object;
const ObjectReturn = @import("object.zig").ObjectReturn;
const Function = @import("object/function.zig").Function;

const Token = @import("../token.zig").Token;
const StatementInterpreter = @import("statement.zig");

const Ast = @import("../ast.zig");
const IntegerLiteral = Ast.IntegerLiteral;
const BooleanLiteral = Ast.BooleanLiteral;
const PrefixExpression = Ast.PrefixExpression;
const BinaryExpression = Ast.BinaryExpression;
const IfExpression = Ast.IfExpression;
const Identifier = Ast.Identifier;
const FunctionLiteral = Ast.FunctionLiteral;
const CallExpression = Ast.CallExpression;

const InterpreterError = @import("error.zig").InterpreterError;
const InterpreterErrors = @import("error.zig").InterpreterErrors;
const Environment = @import("environment.zig").Environment;

pub fn eval(expression: Expression, environment: *Environment) InterpreterErrors!ObjectReturn {
    switch (expression) {
        .integer_literal => return evalIntegerLiteral(expression.integer_literal),
        .boolean_literal => return evalBooleanLiteral(expression.boolean_literal),
        .prefix_expression => return ObjectReturn.object(try evalPrefixExpression(expression.prefix_expression, environment)),
        .binary_expression => return ObjectReturn.object(try evalBinaryExpression(expression.binary_expression, environment)),
        .if_expression => return try evalIfExpression(expression.if_expression, environment),
        .identifier => return try evalIdentifier(expression.identifier, environment),
        .function_literal => return try evalFunctionLiteral(expression.function_literal, environment),
        .call_expression => return try evalCallExpression(expression.call_expression, environment),
    }
}

fn evalBinaryExpression(binary_expression: BinaryExpression, environment: *Environment) !Object {
    const operator = binary_expression.operator;
    const left = (try eval(binary_expression.lvalue.*, environment)).unwrap();
    const right = (try eval(binary_expression.rvalue.*, environment)).unwrap();

    if (left == .integer and right == .integer) {
        return evalIntegerExpression(operator, left, right);
    }
    if (left == .bool and right == .bool) {
        return evalBoolExpression(operator, left, right);
    }

    return Object.null();
}

fn evalIntegerExpression(operator: Token, left: Object, right: Object) Object {
    const l = left.integer.value;
    const r = right.integer.value;
    switch (operator.data) {
        .plus => return Object.integer(l + r),
        .minus => return Object.integer(l - r),
        .asterisk => return Object.integer(l * r),
        .slash => return Object.integer(@divFloor(l, r)),

        .equal => return Object.bool(l == r),
        .not_equal => return Object.bool(l != r),
        .greater_than => return Object.bool(l > r),
        .less_than => return Object.bool(l < r),
        else => return .null,
    }
}

fn evalBoolExpression(operator: Token, left: Object, right: Object) Object {
    const l = left.bool.value;
    const r = right.bool.value;
    switch (operator.data) {
        .equal => return Object.bool(l == r),
        .not_equal => return Object.bool(l != r),
        else => return .null,
    }
}

fn evalPrefixExpression(prefix_expression: PrefixExpression, environment: *Environment) !Object {
    const value = (try eval(prefix_expression.expression.*, environment)).unwrap();
    return switch (prefix_expression.operator.data) {
        .bang => return evalBangOperator(value),
        .minus => return evalMinusPrefixOperator(value),
        else => return .null,
    };
}

fn evalIfExpression(if_expression: IfExpression, environment: *Environment) !ObjectReturn {
    const condition = (try eval(if_expression.condition.*, environment)).unwrap();
    if (condition.is_truthy()) {
        return try StatementInterpreter.eval(if_expression.then.*, environment);
    }
    const else_some = if_expression.else_ orelse return ObjectReturn.object(.null);
    return try StatementInterpreter.eval(else_some.*, environment);
}

fn evalIdentifier(identifier: Identifier, environment: *Environment) !ObjectReturn {
    const value = environment.get(identifier.name) orelse return InterpreterError.IdentifierNotFound;
    return ObjectReturn.object(value);
}

fn evalFunctionLiteral(function_literal: FunctionLiteral, environment: *Environment) !ObjectReturn {
    return ObjectReturn.object(Object.function(try Function.init(environment, function_literal)));
}

fn evalCallExpression(call_expression: CallExpression, environment: *Environment) !ObjectReturn {
    const call_value = (try eval(call_expression.expression.*, environment)).unwrap();
    if (call_value != .function) {
        return ObjectReturn.object(.null);
    }
    const function = call_value.function;

    var child_environment = try function.environment.get_child();

    for (call_expression.arguments.items, function.parameters.items) |expression, parameter| {
        const argument = (try eval(expression, environment)).unwrap();
        try child_environment.set(parameter, argument);
    }
    return try StatementInterpreter.eval(call_value.function.body.*, child_environment);
}

fn evalBangOperator(object: Object) Object {
    return Object.bool(!object.is_truthy());
}

fn evalMinusPrefixOperator(object: Object) Object {
    if (object != .integer) {
        return .null;
    }
    return Object.integer(-object.integer.value);
}

fn evalIntegerLiteral(integer_literal: IntegerLiteral) ObjectReturn {
    return ObjectReturn.object(Object.integer(integer_literal.value));
}

fn evalBooleanLiteral(boolean_literal: BooleanLiteral) ObjectReturn {
    return ObjectReturn.object(Object.bool(boolean_literal.value));
}
