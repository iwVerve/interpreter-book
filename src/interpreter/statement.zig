const Ast = @import("../ast.zig");
const Statement = Ast.Statement;
const LetStatement = @import("../ast.zig").LetStatement;
const ReturnStatement = @import("../ast.zig").ReturnStatement;
const BlockStatement = @import("../ast.zig").BlockStatement;
const Expression = @import("../ast.zig").Expression;

const Object = @import("object.zig").Object;
const ExpressionInterpreter = @import("expression.zig");
const InterpreterErrors = @import("error.zig").InterpreterErrors;

pub fn eval(statement: Statement) InterpreterErrors!Object {
    switch (statement) {
        .let => return .null,
        .return_ => return .null,
        .expression => return try ExpressionInterpreter.eval(statement.expression),
        .block => return try evalBlockStatement(statement.block),
    }
}

pub fn evalBlockStatement(block_statement: BlockStatement) InterpreterErrors!Object {
    var value: Object = undefined;
    for (block_statement.statements.items) |statement| {
        value = try eval(statement);
    }
    return value;
}
