pub const TokenData = union(enum) {
    // Meta
    illegal,

    // Identifiers, literals
    identifier: []const u8,
    integer: []const u8,

    // Operators
    assign,
    plus,
    minus,
    asterisk,
    slash,
    bang,

    less_than,
    greater_than,

    // Delimiters
    comma,
    semicolon,

    paren_l,
    paren_r,
    curly_l,
    curly_r,

    // Keywords
    let,
    function,
    true_,
    false_,
    if_,
    else_,
    return_,
};

pub const Location = struct {
    row: u32,
    column: u32,
};

pub const Token = struct {
    data: TokenData,
    location: Location,
    length: u32,
};
