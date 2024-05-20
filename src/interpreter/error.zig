pub const InterpreterError = error{
    IdentifierNotFound,
};

pub const InterpreterErrors = error{
    OutOfMemory,
    IdentifierNotFound,
};
