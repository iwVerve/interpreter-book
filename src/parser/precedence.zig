const Token = @import("../token.zig").Token;

pub const OperatorPrecedence = enum(u8) {
    lowest,
    equals,
    less_greater,
    sum,
    product,
    prefix,
    call,
};

pub fn getPrecedence(token: Token) ?OperatorPrecedence {
    return switch (token.data) {
        .equal, .not_equal => .equals,
        .less_than, .greater_than => .less_greater,
        .plus, .minus => .sum,
        .asterisk, .slash => .product,
        .paren_l => .call,
        else => null,
    };
}
