const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const Config = @import("../Config.zig");
const ast = @import("../ast.zig");
const Environment = @import("environment.zig").Environment;
const Interpreter = @import("../interpreter.zig").Interpreter;
const Builtin = @import("builtin.zig").Builtin;

pub const Value = union(enum) {
    null,
    integer: Config.integer_type,
    bool: bool,
    function: Function,
    builtin: Builtin,
    allocated: *AllocatedValue,

    pub fn negateInteger(value: Value) !Value {
        if (value == .integer) {
            return .{ .integer = -value.integer };
        }
        return error.TypeError;
    }

    pub fn negateBool(value: Value) !Value {
        return .{ .bool = !isTruthy(value) };
    }

    pub fn isTruthy(value: Value) bool {
        if (value == .bool) {
            return value.bool;
        }
        if (value == .integer) {
            return value.integer > 0;
        }
        if (value == .null) {
            return false;
        }
        return true;
    }

    pub fn add(interpreter: anytype, left: Value, right: Value) !Value {
        if (left == .integer and right == .integer) {
            return .{ .integer = left.integer + right.integer };
        }
        if (left == .allocated and left.allocated.value == .string and right == .allocated and right.allocated.value == .string) {
            const left_string = left.allocated.value.string;
            const right_string = right.allocated.value.string;
            const new_length = left_string.len + right_string.len;
            const new_string = try interpreter.allocator.alloc(u8, new_length);
            errdefer interpreter.allocator.free(new_string);

            @memcpy(new_string.ptr, left_string);
            @memcpy(new_string.ptr + left_string.len, right_string);

            const string_ptr = try AllocatedValue.alloc(interpreter);
            string_ptr.value.string = new_string;

            return .{ .allocated = string_ptr };
        }
        return error.TypeError;
    }

    pub fn subtract(left: Value, right: Value) !Value {
        if (left == .integer and right == .integer) {
            return .{ .integer = left.integer - right.integer };
        }
        return error.TypeError;
    }

    pub fn multiply(left: Value, right: Value) !Value {
        if (left == .integer and right == .integer) {
            return .{ .integer = left.integer * right.integer };
        }
        return error.TypeError;
    }

    pub fn divide(left: Value, right: Value) !Value {
        if (left == .integer and right == .integer) {
            if (right.integer == 0) {
                return error.DivisionByZero;
            }
            const result = @divTrunc(left.integer, right.integer);
            return .{ .integer = result };
        }
        return error.TypeError;
    }

    pub fn equal(left: Value, right: Value) !Value {
        if (left == .integer and right == .integer) {
            return .{ .bool = left.integer == right.integer };
        }
        if (left == .bool and right == .bool) {
            return .{ .bool = left.bool == right.bool };
        }
        return error.TypeError;
    }

    pub fn greater_than(left: Value, right: Value) !Value {
        if (left == .integer and right == .integer) {
            return .{ .bool = left.integer > right.integer };
        }
        return error.TypeError;
    }

    pub fn not_equal(left: Value, right: Value) !Value {
        const is_equal = try Value.equal(left, right);
        return Value.negateBool(is_equal) catch unreachable;
    }

    pub fn less_than(left: Value, right: Value) !Value {
        const is_greater_than = (try Value.greater_than(left, right)).bool;
        const is_equal = (try Value.equal(left, right)).bool;
        return .{ .bool = !is_greater_than and !is_equal };
    }

    /// Caller owns returned memory.
    pub fn string(self: Value, interpreter: anytype) ![]const u8 {
        var array_list = ArrayList(u8).init(interpreter.allocator);
        errdefer array_list.deinit();
        const writer = array_list.writer();

        try self.write(writer);

        return try array_list.toOwnedSlice();
    }

    pub fn write(self: Value, writer: anytype) !void {
        switch (self) {
            .null => try writer.print("null", .{}),
            .integer => |i| try writer.print("{}", .{i}),
            .bool => |b| try writer.print("{}", .{b}),
            .function => try writer.print("function", .{}),
            .builtin => try writer.print("builtin function", .{}),
            .allocated => |a| {
                switch (a.value) {
                    .string => |s| try writer.print("{s}", .{s}),
                }
            },
        }
    }
};

const Function = struct {
    parameters: []const []const u8,
    body: *ast.Statement,
    environment: *Environment,
};

pub const AllocatedValueType = union(enum) {
    string: []const u8,

    pub fn deinit(self: *AllocatedValueType, allocator: Allocator) void {
        switch (self.*) {
            .string => |s| allocator.free(s),
        }
    }
};

pub const AllocatedValue = struct {
    value: AllocatedValueType,

    marked: bool = undefined,
    next: ?*AllocatedValue = undefined,

    pub fn alloc(interpreter: anytype) !*AllocatedValue {
        const allocated_value = try interpreter.allocator.create(AllocatedValue);
        interpreter.append_value(allocated_value);

        if (Config.log_gc) {
            std.debug.print("GC alloc val: {*}\n", .{allocated_value});
        }

        return allocated_value;
    }

    pub fn deinit(self: *AllocatedValue, allocator: Allocator) void {
        self.value.deinit(allocator);
        allocator.destroy(self);
    }

    pub fn unmark(self: *AllocatedValue) void {
        self.marked = false;
    }

    pub fn mark(self: *AllocatedValue) void {
        if (self.marked) {
            return;
        }

        self.marked = true;
    }
};
