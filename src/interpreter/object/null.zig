pub const Null = struct {
    pub fn write(self: Null, writer: anytype) !void {
        _ = self;
        _ = try writer.write("<null>");
    }
};
