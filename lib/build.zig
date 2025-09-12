const std = @import("std");

pub fn build(b: *std.Build) void {
    b.addModule("shared", .{
        .source_file = .{ .path = "src/main.zig" },
    });
}
