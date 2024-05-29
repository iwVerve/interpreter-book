const std = @import("std");
const Allocator = std.mem.Allocator;

const Value = @import("value.zig").Value;
const Interpreter = @import("../interpreter.zig").Interpreter;

pub const Environment = struct {
    allocator: Allocator,
    hash_map: std.StringArrayHashMap(Value) = undefined,
    parent: ?*Environment,

    marked: bool = undefined,
    next: ?*Environment = null,

    pub fn init(allocator: Allocator, parent: ?*Environment) Environment {
        const hash_map = std.StringArrayHashMap(Value).init(allocator);
        return .{ .hash_map = hash_map, .allocator = allocator, .parent = parent };
    }

    pub fn deinit(self: *Environment) void {
        self.hash_map.deinit();
        self.allocator.destroy(self);
    }

    pub fn extend(self: *Environment) Environment {
        return Environment.init(self.allocator, self);
    }

    pub fn set(self: *Environment, key: []const u8, value: Value) !void {
        try self.hash_map.put(key, value);
    }

    pub fn get(self: Environment, key: []const u8) ?Value {
        var result = self.hash_map.get(key);
        if (result == null and self.parent != null) {
            result = self.parent.?.get(key);
        }
        return result;
    }

    pub fn unmark(self: *Environment) void {
        self.marked = false;
    }

    pub fn mark(self: *Environment) void {
        if (self.marked) {
            return;
        }

        self.marked = true;

        if (self.parent) |parent_ptr| {
            parent_ptr.mark();
        }

        for (self.hash_map.values()) |value| {
            switch (value) {
                .function => |f| f.environment.mark(),
                .allocated => |a| a.mark(),
                else => {},
            }
        }
    }
};
