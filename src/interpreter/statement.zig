const std = @import("std");

const Ast = @import("../ast.zig");
const Statement = Ast.Statement;
const LetStatement = @import("../ast.zig").LetStatement;
const ReturnStatement = @import("../ast.zig").ReturnStatement;
const BlockStatement = @import("../ast.zig").BlockStatement;
const Expression = @import("../ast.zig").Expression;

const Object = @import("object.zig").Object;
const ObjectReturn = @import("object.zig").ObjectReturn;
const ExpressionInterpreter = @import("expression.zig");
const InterpreterErrors = @import("error.zig").InterpreterErrors;

const Environment = @import("environment.zig").Environment;

pub fn evalProgram(program: BlockStatement, allocator: std.mem.Allocator) !ObjectReturn {
    var environment = Environment.init(allocator);
    defer environment.deinit();

    return try evalBlockStatement(program, &environment);
}

pub fn eval(statement: Statement, environment: *Environment) InterpreterErrors!ObjectReturn {
    switch (statement) {
        .let => return try evalLetStatement(statement.let, environment),
        .return_ => return try evalReturnStatement(statement.return_, environment),
        .expression => return try ExpressionInterpreter.eval(statement.expression, environment),
        .block => return try evalBlockStatement(statement.block, environment),
    }
}

pub fn evalLetStatement(let_statement: LetStatement, environment: *Environment) !ObjectReturn {
    const value = (try ExpressionInterpreter.eval(let_statement.expression, environment)).unwrap();
    try environment.set(let_statement.identifier.name, value);

    return ObjectReturn.object(.null);
}

pub fn evalReturnStatement(return_statement: ReturnStatement, environment: *Environment) !ObjectReturn {
    const value = (try ExpressionInterpreter.eval(return_statement.expression, environment)).unwrap();
    return .{ .return_ = value };
}

pub fn evalBlockStatement(block_statement: BlockStatement, environment: *Environment) !ObjectReturn {
    var value: ObjectReturn = .{ .object = Object.null() };
    for (block_statement.statements.items) |statement| {
        value = try eval(statement, environment);
        if (value == .return_) {
            break;
        }
    }
    return value;
}
