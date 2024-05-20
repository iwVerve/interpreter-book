const Null = @import("object/null.zig").Null;
const Bool = @import("object/bool.zig").Bool;
const Integer = @import("object/integer.zig").Integer;
const Function = @import("object/function.zig").Function;

pub const Object = union(enum) {
    null: Null,
    bool: Bool,
    integer: Integer,
    function: Function,

    pub fn integer(value: i64) Object {
        return .{ .integer = .{ .value = value } };
    }

    pub fn @"bool"(value: bool) Object {
        return .{ .bool = .{ .value = value } };
    }

    pub fn @"null"() Object {
        return .null;
    }

    pub fn function(value: Function) Object {
        return .{ .function = value };
    }

    pub fn is_truthy(self: Object) bool {
        return switch (self) {
            .bool => self.bool.value,
            .integer => true,
            .null => false,
            .function => true,
        };
    }

    pub fn write(self: Object, writer: anytype) !void {
        switch (self) {
            .null => try self.null.write(writer),
            .bool => try self.bool.write(writer),
            .integer => try self.integer.write(writer),
            .function => try self.function.write(writer),
        }
    }
};

pub const ObjectReturn = union(enum) {
    object: Object,
    return_: Object,

    pub fn write(self: ObjectReturn, writer: anytype) !void {
        try self.unwrap().write(writer);
    }

    pub fn unwrap(self: ObjectReturn) Object {
        switch (self) {
            .object => return self.object,
            .return_ => return self.return_,
        }
    }

    pub fn object(value: Object) ObjectReturn {
        return .{ .object = value };
    }

    pub fn return_(value: Object) ObjectReturn {
        return .{ .return_ = value };
    }
};
