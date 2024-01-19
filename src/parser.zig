const std = @import("std");
const ArrayList = std.ArrayList;
const Lexer = @import("lexer.zig").Lexer;
const Token = @import("token.zig").Token;
const TokenData = @import("token.zig").TokenData;

const ast = @import("ast.zig");
const Statement = ast.Statement;
const LetStatement = ast.LetStatement;
const Expression = ast.Expression;
const Identifier = ast.Identifier;

const ParserError = error{
    SuddenEOF,
    ExpectedAssign,
    ExpectedSemicolon,
    ExpectedParenL,
    ExpectedParenR,
    ExpectedCurlyR,
    UnexpectedToken,
};

const OperatorPrecedence = enum(u8) {
    lowest,
    equals,
    less_greater,
    sum,
    product,
    prefix,
    call,
};

pub const Parser = struct {
    lexer: Lexer,
    current_token: ?Token = null,
    allocator: std.mem.Allocator,

    const ParserErrors = error{
        OutOfMemory,
        Overflow,
        SuddenEOF,
        UnexpectedToken,
        ExpectedAssign,
        ExpectedParenL,
        ExpectedParenR,
        ExpectedCurlyR,
        ExpectedSemicolon,
        InvalidCharacter,
    };

    pub fn parse(allocator: std.mem.Allocator, input: []const u8) !ArrayList(Statement) {
        var lexer = Lexer.init(input);
        var parser = Parser{ .lexer = lexer, .allocator = allocator };
        parser.advanceToken();
        return try parser.parseStatements();
    }

    fn parseStatements(self: *Parser) !ArrayList(Statement) {
        var statements = ArrayList(Statement).init(self.allocator);
        while (true) {
            const peek = self.peekToken() orelse break;
            if (peek.data == .curly_r) {
                break;
            }
            const statement = (try self.parseStatement()) orelse break;
            try statements.append(statement);
        }
        return statements;
    }

    fn parseStatement(self: *Parser) !?Statement {
        const token = self.peekToken() orelse return null;
        return switch (token.data) {
            .let => try self.parseLetStatement(),
            .return_ => try self.parseReturnStatement(),
            .curly_l => try self.parseBlockStatement(),
            else => try self.parseExpressionStatement(),
        };
    }

    fn parseLetStatement(self: *Parser) !Statement {
        self.advanceToken(); // Guaranteed .let
        const identifier = try self.parseIdentifier();
        const assign = self.nextToken() orelse return ParserError.SuddenEOF;
        if (assign.data != TokenData.assign) return ParserError.ExpectedAssign;
        const expression = try self.parseExpression(.lowest);
        const semicolon = self.nextToken() orelse return ParserError.SuddenEOF;
        if (semicolon.data != TokenData.semicolon) return ParserError.ExpectedSemicolon;
        return .{ .let = .{
            .identifier = identifier,
            .expression = expression,
        } };
    }

    fn parseReturnStatement(self: *Parser) !Statement {
        self.advanceToken(); // Guaranteed .return
        const expression = try self.parseExpression(.lowest);
        const semicolon = self.nextToken() orelse return ParserError.SuddenEOF;
        if (semicolon.data != TokenData.semicolon) return ParserError.ExpectedSemicolon;
        return .{ .return_ = .{
            .expression = expression,
        } };
    }

    fn parseExpressionStatement(self: *Parser) !Statement {
        const expression = try self.parseExpression(.lowest);

        // Optional semicolon
        const peek = self.peekToken();
        if (peek) |token| {
            if (token.data == .semicolon) {
                self.advanceToken();
            }
        }

        return .{ .expression = expression };
    }

    fn parseBlockStatement(self: *Parser) ParserErrors!Statement {
        self.advanceToken(); // Guaranteed.curly_l
        const statements = try self.parseStatements();
        const curly_r = self.nextToken() orelse return ParserError.SuddenEOF;
        if (curly_r.data != .curly_r) {
            return ParserError.ExpectedCurlyR;
        }
        return .{ .block = .{ .statements = statements } };
    }

    fn parseExpression(self: *Parser, precedence: OperatorPrecedence) !Expression {
        const token = self.peekToken() orelse return ParserError.SuddenEOF;
        var left = try self.callPrefixFunction(token) orelse return ParserError.UnexpectedToken;
        while (true) {
            // Break if EOF or semicolon
            const peek = self.peekToken() orelse break;
            if (peek.data == TokenData.semicolon) {
                break;
            }
            // Break if no assigned infix function
            const peek_precedence = getPrecedence(peek) orelse break;
            // Break if lower precedence
            if (@intFromEnum(peek_precedence) < @intFromEnum(precedence)) {
                break;
            }
            const infix = self.peekToken() orelse unreachable;
            left = try self.callInfixFunction(infix, left) orelse unreachable;
        }
        return left;
    }

    fn getPrecedence(token: Token) ?OperatorPrecedence {
        return switch (token.data) {
            .equal, .not_equal => .equals,
            .less_than, .greater_than => .less_greater,
            .plus, .minus => .sum,
            .asterisk, .slash => .product,
            .paren_l => .call,
            else => null,
        };
    }

    fn callPrefixFunction(self: *Parser, token: Token) !?Expression {
        return switch (token.data) {
            .identifier => try self.parseIdentifierExpression(),
            .integer => try self.parseIntegerExpression(),
            .bang, .minus => try self.parsePrefixExpression(),
            .true_, .false_ => try self.parseBooleanExpression(),
            .paren_l => try self.parseGroupedExpression(),
            .if_ => try self.parseIfExpression(),
            .function => try self.parseFunctionExpression(),
            else => null,
        };
    }

    fn callInfixFunction(self: *Parser, token: Token, expression: Expression) !?Expression {
        return switch (token.data) {
            .plus,
            .minus,
            .asterisk,
            .slash,
            .equal,
            .not_equal,
            .less_than,
            .greater_than,
            => try self.parseInfixExpression(expression),
            .paren_l => try self.parseCallExpression(expression),
            else => null,
        };
    }

    fn parsePrefixExpression(self: *Parser) ParserErrors!Expression {
        const operator = self.nextToken() orelse return ParserError.SuddenEOF;
        const expression = try self.allocator.create(Expression);
        expression.* = try self.parseExpression(.prefix);

        return .{ .prefix_expression = .{ .operator = operator, .expression = expression } };
    }

    fn parseInfixExpression(self: *Parser, left: Expression) ParserErrors!Expression {
        const operator = self.nextToken() orelse return ParserError.SuddenEOF;
        const precedence = getPrecedence(operator) orelse return ParserError.UnexpectedToken;
        const left_ptr = try self.allocator.create(Expression);
        left_ptr.* = left;
        const right = try self.allocator.create(Expression);
        right.* = try self.parseExpression(precedence);
        return .{ .binary_expression = .{
            .lvalue = left_ptr,
            .operator = operator,
            .rvalue = right,
        } };
    }

    fn parseCallExpression(self: *Parser, left: Expression) ParserErrors!Expression {
        self.advanceToken(); // Guaranteed .paren_l
        const expression = try self.allocator.create(Expression);
        expression.* = left;
        const arguments = try self.parseCallArguments();
        return .{ .call_expression = .{ .expression = expression, .arguments = arguments } };
    }

    fn parseCallArguments(self: *Parser) ParserErrors!ArrayList(Expression) {
        var arguments = ArrayList(Expression).init(self.allocator);
        while (true) {
            try arguments.append(try self.parseExpression(.lowest));
            const peek = self.nextToken() orelse return ParserError.SuddenEOF;
            switch (peek.data) {
                .comma => {},
                .paren_r => break,
                else => return ParserError.UnexpectedToken,
            }
        }
        return arguments;
    }

    fn parseIfExpression(self: *Parser) ParserErrors!Expression {
        self.advanceToken(); // Guaranteed .if
        const condition = try self.allocator.create(Expression);
        condition.* = try self.parseExpression(.lowest);
        const then = try self.allocator.create(Statement);
        then.* = try self.parseStatement() orelse return ParserError.UnexpectedToken;
        var else_: ?*Statement = null;
        if (self.peekToken()) |peek| {
            if (peek.data == .else_) {
                self.advanceToken();
                else_ = try self.allocator.create(Statement);
                else_.?.* = try self.parseStatement() orelse return ParserError.UnexpectedToken;
            }
        }
        return .{ .if_expression = .{ .condition = condition, .then = then, .else_ = else_ } };
    }

    fn parseFunctionExpression(self: *Parser) ParserErrors!Expression {
        self.advanceToken(); // Guaranteed .function
        const paren_l = self.nextToken() orelse return ParserError.SuddenEOF;
        if (paren_l.data != .paren_l) {
            return ParserError.ExpectedParenL;
        }
        var parameters = ArrayList(Identifier).init(self.allocator);
        while (true) {
            try parameters.append(try self.parseIdentifier());
            const next = self.nextToken() orelse return ParserError.SuddenEOF;
            switch (next.data) {
                .comma => {},
                .paren_r => break,
                else => return ParserError.UnexpectedToken,
            }
        }
        const body = try self.allocator.create(Statement);
        body.* = try self.parseStatement() orelse return ParserError.UnexpectedToken;
        return .{ .function_literal = .{ .parameters = parameters, .body = body } };
    }

    fn parseIdentifierExpression(self: *Parser) !Expression {
        const identifier = try self.parseIdentifier();
        return .{ .identifier = identifier };
    }

    fn parseIntegerExpression(self: *Parser) !Expression {
        const integer = self.nextToken() orelse return ParserError.SuddenEOF;
        return .{ .integer_literal = .{ .token = integer, .value = try std.fmt.parseInt(i64, integer.data.integer, 10) } };
    }

    fn parseIdentifier(self: *Parser) !Identifier {
        const name = self.nextToken() orelse return ParserError.SuddenEOF;
        return .{
            .token = name,
            .name = name.data.identifier,
        };
    }

    fn parseBooleanExpression(self: *Parser) !Expression {
        const boolean = self.nextToken() orelse return ParserError.SuddenEOF;
        const value = switch (boolean.data) {
            .true_ => true,
            .false_ => false,
            else => return ParserError.UnexpectedToken,
        };
        return .{ .boolean_literal = .{
            .token = boolean,
            .value = value,
        } };
    }

    fn parseGroupedExpression(self: *Parser) ParserErrors!Expression {
        self.advanceToken(); // Guaranteed .paren_l
        const expression = try self.parseExpression(.lowest);
        const paren_r = self.peekToken() orelse return ParserError.SuddenEOF;
        if (paren_r.data != .paren_r) {
            return ParserError.ExpectedParenR;
        }
        self.advanceToken();
        return expression;
    }

    fn nextToken(self: *Parser) ?Token {
        const token = self.current_token;
        self.advanceToken();
        return token;
    }

    fn advanceToken(self: *Parser) void {
        self.current_token = self.lexer.nextToken();
    }

    fn peekToken(self: *Parser) ?Token {
        return self.current_token;
    }
};
