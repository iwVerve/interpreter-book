pub const ParserError = error{
    SuddenEOF,
    ExpectedAssign,
    ExpectedSemicolon,
    ExpectedParenL,
    ExpectedParenR,
    ExpectedCurlyR,
    UnexpectedToken,
};

pub const ParserErrors = error{
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
