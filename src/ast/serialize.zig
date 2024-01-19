const std = @import("std");

pub const SerializeOptions = struct {
    debug: bool = false,
    indent: u32 = 0,
    top_level: bool = true,
};

pub const SerializeErrors = error{
    DiskQuota,
    FileTooBig,
    InputOutput,
    NoSpaceLeft,
    DeviceBusy,
    InvalidArgument,
    AccessDenied,
    BrokenPipe,
    SystemResources,
    OperationAborted,
    NotOpenForWriting,
    LockViolation,
    WouldBlock,
    ConnectionResetByPeer,
    Unexpected,
};
