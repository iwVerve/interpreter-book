const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Expression = union(enum) {
    identifier: Identifier,

    pub fn deinit(self: *Expression, allocator: Allocator) void {
        switch (self.*) {
            .identifier => |*i| i.deinit(allocator),
        }
    }
};

pub const Identifier = struct {
    name: []const u8,

    pub fn deinit(self: *Identifier, allocator: Allocator) void {
        allocator.free(self.name);
    }
};
