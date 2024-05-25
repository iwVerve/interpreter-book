const std = @import("std");
const Allocator = std.mem.Allocator;

const Config = @import("../Config.zig");

pub const Expression = union(enum) {
    identifier: Identifier,
    integer: Config.integer_type,

    pub fn deinit(self: *Expression, allocator: Allocator) void {
        switch (self.*) {
            .identifier => |*i| i.deinit(allocator),
            .integer => {},
        }
    }

    pub fn write(self: Expression, writer: anytype) !void {
        switch (self) {
            .identifier => |i| try i.write(writer),
            .integer => |i| try writer.print("{}", .{i}),
        }
    }
};

pub const Identifier = struct {
    name: []const u8,

    pub fn deinit(self: *Identifier, allocator: Allocator) void {
        allocator.free(self.name);
    }

    pub fn write(self: Identifier, writer: anytype) !void {
        try writer.print("{s}", .{self.name});
    }
};
