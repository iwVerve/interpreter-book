pub const Token = union(enum) {
    illegal,
    eof,

    identifier: []const u8,
    integer: u32,

    assign,
    add,

    comma,
    semicolon,

    paren_l,
    paren_r,
    brace_l,
    brace_r,

    function,
    let,
};
