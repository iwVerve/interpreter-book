const StatementImpl = @import("ast/statement.zig");
pub const Statement = StatementImpl.Statement;
pub const LetStatement = StatementImpl.LetStatement;
pub const ReturnStatement = StatementImpl.ReturnStatement;
pub const BlockStatement = StatementImpl.BlockStatement;

const ExpressionImpl = @import("ast/expression.zig");
pub const Expression = ExpressionImpl.Expression;

pub const BinaryExpression = ExpressionImpl.BinaryExpression;
pub const PrefixExpression = ExpressionImpl.PrefixExpression;

pub const IntegerLiteral = ExpressionImpl.IntegerLiteral;
pub const Identifier = ExpressionImpl.Identifier;
pub const BooleanLiteral = ExpressionImpl.BooleanLiteral;
pub const FunctionLiteral = ExpressionImpl.FunctionLiteral;

pub const IfExpression = ExpressionImpl.IfExpression;
pub const CallExpression = ExpressionImpl.CallExpression;
