pub const StatementImpl = @import("ast/statement.zig");
pub const ExpressionImpl = @import("ast/expression.zig");

pub const Statement = StatementImpl.Statement;
pub const BlockStatement = StatementImpl.BlockStatement;
pub const LetStatement = StatementImpl.LetStatement;

pub const Expression = ExpressionImpl.Expression;
pub const Identifier = ExpressionImpl.Identifier;
