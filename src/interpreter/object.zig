const Null = @import("object/null.zig").Null;
const Bool = @import("object/bool.zig").Bool;
const Integer = @import("object/integer.zig").Integer;

pub const Object = union(enum) {
    null: Null,
    bool: Bool,
    integer: Integer,

    pub fn write(self: Object, writer: anytype) !void {
        switch (self) {
            .null => try self.null.write(writer),
            .bool => try self.bool.write(writer),
            .integer => try self.integer.write(writer),
        }
    }
};
