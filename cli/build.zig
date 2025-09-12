const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create shared module dependency
    const shared_dep = b.dependency("shared", .{
        .target = target,
        .optimize = optimize,
    });
    const shared_mod = shared_dep.module("shared");

    // Create CLI module
    const cli_mod = b.addModule("cli", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &[_]std.Build.Module.Import{
            .{ .name = "shared", .module = shared_mod },
        },
    });

    // Build executable
    const exe = b.addExecutable(.{
        .name = "cli",
        .root_module = cli_mod,
    });
    b.installArtifact(exe);
}
