const InterpreterImpl = @import("../interpreter.zig");
const Interpreter = InterpreterImpl.Interpreter;
const InterpreterError = InterpreterImpl.InterpreterError;

const ast = @import("../ast.zig");
const Value = @import("value.zig").Value;
const Environment = @import("environment.zig").Environment;

pub fn evalReturnStatement(self: *Interpreter, statement: ast.ReturnStatement, environment: *Environment) !Value {
    const value = try self.evalExpression(statement.expression, environment);
    self.return_state = .function;
    return value;
}

pub fn evalLetStatement(self: *Interpreter, statement: ast.LetStatement, environment: *Environment) !Value {
    const value = try self.evalExpression(statement.expression, environment);
    try environment.set(statement.identifier.name, value);
    return value;
}

pub fn evalStatement(self: *Interpreter, statement: ast.Statement, environment: *Environment) InterpreterError!Value {
    return switch (statement) {
        .block => |b| try self.evalStatements(b, environment),
        .expression => |e| try self.evalExpression(e, environment),
        .return_ => |r| try self.evalReturnStatement(r, environment),
        .let => |l| try self.evalLetStatement(l, environment),
    };
}

pub fn evalStatements(self: *Interpreter, statements: ast.BlockStatement, environment: *Environment) !Value {
    var result: Value = .null;

    for (statements.statements) |statement| {
        result = try self.evalStatement(statement, environment);

        if (self.return_state == .function) {
            break;
        }
    }

    self.gc(environment, &result);

    return result;
}
