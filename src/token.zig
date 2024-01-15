pub const Token = union(enum) {
    illegal: void,
    eof: void,

    identifier: []const u8,
    integer: []const u8,

    assign: void,
    bang: void,
    plus: void,
    minus: void,
    asterisk: void,
    slash: void,

    equal: void,
    not_equal: void,
    less_than: void,
    greater_than: void,

    comma: void,
    semicolon: void,
    paren_l: void,
    paren_r: void,
    curly_l: void,
    curly_r: void,

    function: void,
    let: void,
    true: void,
    false: void,
    if_: void,
    else_: void,
    return_: void,
};
