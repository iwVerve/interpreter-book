const Interpreter = @import("../interpreter.zig").Interpreter;
const Config = @import("../Config.zig");

const ast = @import("../ast.zig");

pub fn Impl(comptime WriterType: anytype) type {
    const Self = Interpreter(WriterType);

    return struct {
        const InterpreterError = Self.InterpreterError;
        const Value = Self.Value;
        const Environment = Self.Environment;

        pub fn evalReturnStatement(self: *Self, statement: ast.ReturnStatement, environment: *Environment) !Value {
            const value = try self.evalExpression(statement.expression, environment);
            self.return_state = .function;
            return value;
        }

        pub fn evalLetStatement(self: *Self, statement: ast.LetStatement, environment: *Environment) !Value {
            const value = try self.evalExpression(statement.expression, environment);
            if (statement.declare) {
                try environment.set(statement.identifier.name, value);
            } else {
                try environment.update(statement.identifier.name, value);
            }
            return value;
        }

        pub fn evalWhileStatement(self: *Self, statement: ast.WhileStatement, environment: *Environment) !Value {
            while (true) {
                const condition = try self.evalExpression(statement.condition, environment);
                if (!Value.isTruthy(condition)) {
                    break;
                }

                _ = try self.evalStatement(statement.body.*, environment);
                if (self.return_state != .none) {
                    break;
                }
            }

            return .null;
        }

        pub fn evalStatement(self: *Self, statement: ast.Statement, environment: *Environment) InterpreterError!Value {
            return switch (statement) {
                .block => |b| try self.evalStatements(b, environment),
                .expression => |e| try self.evalExpression(e, environment),
                .return_ => |r| try self.evalReturnStatement(r, environment),
                .let => |l| try self.evalLetStatement(l, environment),
                .while_ => |w| try self.evalWhileStatement(w, environment),
            };
        }

        pub fn evalStatements(self: *Self, statements: ast.BlockStatement, environment: *Environment) !Value {
            var result: Value = .null;

            for (statements.statements) |statement| {
                result = try self.evalStatement(statement, environment);

                if (self.return_state == .function) {
                    break;
                }
            }

            if (self.allocations_since_gc >= Config.allocation_threshold) {
                self.gc(environment, &result);
            }

            return result;
        }
    };
}
