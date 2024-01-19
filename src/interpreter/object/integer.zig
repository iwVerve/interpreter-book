pub const Integer = struct {
    value: i64,

    pub fn write(self: Integer, writer: anytype) !void {
        try writer.print("{}", .{self.value});
    }
};
