const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard target options
    const target = b.standardTargetOptions(.{});

    // Standard optimization options
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseFast,
    });

    // Create the main executable
    const exe = b.addExecutable(.{
        .name = "voltedge-sim",
        .root_source_file = b.path("src/simple_main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Note: External dependencies removed for initial testing
    // TODO: Add gRPC integration in future iteration

    // Install the executable
    b.installArtifact(exe);

    // Create a run step
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the VoltEdge simulation engine");
    run_step.dependOn(&run_cmd.step);

    // Create test step
    const exe_tests = b.addTest(.{
        .root_source_file = b.path("src/simple_main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);

    // Create benchmark step
    const bench_exe = b.addExecutable(.{
        .name = "bench",
        .root_source_file = b.path("bench/benchmark.zig"),
        .target = target,
        .optimize = .ReleaseFast,
    });

    const bench_cmd = b.addRunArtifact(bench_exe);
    const bench_step = b.step("bench", "Run performance benchmarks");
    bench_step.dependOn(&bench_cmd.step);
}

pub fn addModule(b: *std.Build, name: []const u8, source_file: []const u8) *std.Build.Module {
    return b.addModule(name, .{
        .root_source_file = b.path(source_file),
    });
}
