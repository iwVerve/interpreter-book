pub const Token = union(enum) {
    illegal,
    eof,

    identifier: []const u8,
    integer: u32,

    assign,
    plus,
    minus,
    bang,
    asterisk,
    slash,

    equal,
    not_equal,
    less_than,
    greater_than,

    comma,
    semicolon,

    paren_l,
    paren_r,
    brace_l,
    brace_r,

    function,
    let,
    true,
    false,
    if_,
    else_,
    return_,
};

pub const operators = .{
    .{ "=", .assign },

    .{ "+", .plus },
    .{ "-", .minus },
    .{ "*", .asterisk },
    .{ "/", .slash },
    .{ "!", .bang },

    .{ "==", .equal },
    .{ "!=", .not_equal },
    .{ "<", .less_than },
    .{ ">", .greater_than },

    .{ ",", .comma },
    .{ ";", .semicolon },

    .{ "(", .paren_l },
    .{ ")", .paren_r },
    .{ "{", .brace_l },
    .{ "}", .brace_r },
};

pub const keywords = .{
    .{ "let", .let },
    .{ "fn", .function },
    .{ "true", .true },
    .{ "false", .false },
    .{ "if", .if_ },
    .{ "else", .else_ },
    .{ "return", .return_ },
};
