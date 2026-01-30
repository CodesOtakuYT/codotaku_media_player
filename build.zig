const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const core = b.addLibrary(.{
        .name = "core",
        .root_module = b.addModule("core", .{
            .root_source_file = b.path("src/core/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const platform = b.addLibrary(.{
        .name = "platform",
        .root_module = b.addModule("platform", .{
            .root_source_file = b.path("src/platform/root.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    platform.root_module.addImport("core", core.root_module);
    platform.root_module.linkSystemLibrary("SDL3", .{});

    const media = b.addLibrary(.{
        .name = "media",
        .root_module = b.addModule("media", .{
            .root_source_file = b.path("src/media/root.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    media.root_module.addImport("core", core.root_module);
    media.root_module.linkSystemLibrary("avformat", .{});
    media.root_module.linkSystemLibrary("avcodec", .{});
    media.root_module.linkSystemLibrary("avutil", .{});

    const exe = b.addExecutable(.{ .name = "codotaku_media_player", .root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    }) });
    exe.root_module.addImport("core", core.root_module);
    exe.root_module.addImport("platform", platform.root_module);
    exe.root_module.addImport("media", media.root_module);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args|
        run_cmd.addArgs(args);

    const run_step = b.step("run", "Run the media player");
    run_step.dependOn(&run_cmd.step);
}
