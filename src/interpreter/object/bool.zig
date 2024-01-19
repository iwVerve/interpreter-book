pub const Bool = struct {
    value: bool,

    pub fn write(self: Bool, writer: anytype) !void {
        try writer.print("{}", .{self.value});
    }
};
