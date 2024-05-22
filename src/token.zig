pub const Token = union(enum) {
    illegal,
    eof,

    identifier,
    integer,

    assign,
    plus,

    comma,
    semicolon,

    paren_l,
    paren_r,
    brace_l,
    brace_r,

    function,
    let,
};
