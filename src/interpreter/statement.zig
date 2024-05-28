const InterpreterImpl = @import("../interpreter.zig");
const Interpreter = InterpreterImpl.Interpreter;
const InterpreterError = InterpreterImpl.InterpreterError;

const ast = @import("../ast.zig");
const Value = @import("value.zig").Value;

pub fn evalReturnStatement(self: *Interpreter, statement: ast.ReturnStatement) !Value {
    const value = try self.evalExpression(statement.expression);
    self.return_state = .function;
    return value;
}

pub fn evalLetStatement(self: *Interpreter, statement: ast.LetStatement) !Value {
    const value = try self.evalExpression(statement.expression);
    try self.root.set(statement.identifier.name, value);
    return value;
}

pub fn evalStatement(self: *Interpreter, statement: ast.Statement) InterpreterError!Value {
    return switch (statement) {
        .block => |b| try self.evalStatements(b),
        .expression => |e| try self.evalExpression(e),
        .return_ => |r| try self.evalReturnStatement(r),
        .let => |l| try self.evalLetStatement(l),
    };
}

pub fn evalStatements(self: *Interpreter, statements: ast.BlockStatement) !Value {
    var result: Value = .null;

    for (statements.statements) |statement| {
        result = try self.evalStatement(statement);

        if (self.return_state == .function) {
            break;
        }
    }

    return result;
}
