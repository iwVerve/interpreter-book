const std = @import("std");

pub const SerializeOptions = struct {
    allocator: std.mem.Allocator,
    debug: bool = false,
};

pub const SerializeErrors = error{
    OutOfMemory,
};
