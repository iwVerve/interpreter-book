const Config = @import("../Config.zig");

pub const Value = union(enum) {
    null,
    integer: Config.integer_type,
    bool: bool,

    pub fn negateInteger(value: Value) !Value {
        if (value == .integer) {
            return .{ .integer = -value.integer };
        }
        return error.TypeError;
    }

    pub fn negateBool(value: Value) !Value {
        if (value == .bool) {
            return .{ .bool = !value.bool };
        }
        return error.TypeError;
    }

    pub fn add(left: Value, right: Value) !Value {
        if (left == .integer and right == .integer) {
            return .{ .integer = left.integer + right.integer };
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
            const result = @divTrunc(left.integer, right.integer);
            return .{ .integer = result };
        }
        return error.TypeError;
    }
};
