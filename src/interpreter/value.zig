const Config = @import("../Config.zig");
const ast = @import("../ast.zig");
const Environment = @import("environment.zig").Environment;

pub const Value = union(enum) {
    null,
    integer: Config.integer_type,
    bool: bool,
    function: Function,

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
};

const Function = struct {
    parameters: []const []const u8,
    body: *ast.Statement,
    environment: Environment,
};
