const std = @import("std");
const Object = @import("object.zig").Object;

pub const Environment = struct {
    allocator: std.mem.Allocator,
    map: std.StringHashMap(Object),
    parent: ?*Environment = null,

    pub fn init(allocator: std.mem.Allocator) Environment {
        const map = std.StringHashMap(Object).init(allocator);
        return .{
            .allocator = allocator,
            .map = map,
        };
    }

    pub fn deinit(self: *Environment) void {
        self.map.deinit();
    }

    pub fn get_child(self: *Environment) !*Environment {
        var environment = try self.allocator.create(Environment);
        environment.* = Environment.init(self.allocator);
        environment.parent = self;
        return environment;
    }

    pub fn set(self: *Environment, key: []const u8, value: Object) !void {
        const owned_key = try self.allocator.dupe(u8, key);
        try self.map.put(owned_key, value);
    }

    pub fn get(self: *Environment, key: []const u8) ?Object {
        if (self.map.get(key)) |object| {
            return object;
        }
        if (self.parent) |parent| {
            return parent.get(key);
        }
        return null;
    }

    pub fn write(self: Environment, writer: anytype) !void {
        _ = try writer.write("Environment:\n");
        var iterator = self.map.iterator();
        while (iterator.next()) |entry| {
            try writer.print("{s}\n", .{entry.key_ptr.*});
        }

        if (self.parent) |parent| {
            _ = try writer.write("Parent:\n");
            try parent.write(writer);
        }
    }
};
