const std = @import("std");

pub fn build(b: *std.Build) void {
    // Compute target once
    const target = b.standardTargetOptions(.{});

    // Create the shared module
    const shared_mod = b.addModule("shared", .{
        .root_source_file = b.path("lib/src/main.zig"),
        .target = target,
    });

    // Build the shared library
    const shared_lib = b.addLibrary(.{
        .name = "shared",
        .root_module = shared_mod,
    });
    b.installArtifact(shared_lib);

    // Build the CLI executable and link to the shared library
    const exe_mod = b.addModule("cli", .{
        .root_source_file = b.path("cli/src/main.zig"),
        .target = target,
        .imports = &[_]std.Build.Module.Import{.{ .name = "shared", .module = shared_mod }},
    });

    const exe = b.addExecutable(.{
        .name = "cli",
        .root_module = exe_mod,
    });
    exe.linkLibrary(shared_lib);
    b.installArtifact(exe);
}
