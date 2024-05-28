const std = @import("std");
const Allocator = std.mem.Allocator;

const Value = @import("value.zig").Value;

pub const Environment = struct {
    hash_map: std.StringArrayHashMap(Value) = undefined,

    pub fn init(allocator: Allocator) Environment {
        const hash_map = std.StringArrayHashMap(Value).init(allocator);
        return .{ .hash_map = hash_map };
    }

    pub fn set(self: *Environment, key: []const u8, value: Value) !void {
        try self.hash_map.put(key, value);
    }

    pub fn get(self: Environment, key: []const u8) ?Value {
        return self.hash_map.get(key);
    }

    pub fn deinit(self: *Environment) void {
        self.hash_map.deinit();
    }
};
