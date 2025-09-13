const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard target and optimization options
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_arch = .x86_64,
            .os_tag = .linux,
            .abi = .gnu,
        },
    });
    
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseFast,
    });
    
    // Advanced compilation flags for maximum performance
    const exe = b.addExecutable(.{
        .name = "voltedge-optimized",
        .root_source_file = b.path("src/optimized_main.zig"),
        .target = target,
        .optimize = optimize,
    });
    
    // Enable all available optimizations
    exe.addCSourceFlag("-march=native");
    exe.addCSourceFlag("-mtune=native");
    exe.addCSourceFlag("-flto");
    exe.addCSourceFlag("-ffast-math");
    exe.addCSourceFlag("-funroll-loops");
    exe.addCSourceFlag("-fvectorize");
    exe.addCSourceFlag("-fopenmp");
    
    // Enable SIMD instructions
    exe.addCSourceFlag("-mavx2");
    exe.addCSourceFlag("-mfma");
    exe.addCSourceFlag("-msse4.2");
    
    // Memory and cache optimizations
    exe.addCSourceFlag("-fprefetch-loop-arrays");
    exe.addCSourceFlag("-fprofile-use");
    
    // Link-time optimizations
    exe.addCSourceFlag("-Wl,--gc-sections");
    exe.addCSourceFlag("-Wl,--strip-all");
    
    // Set optimization level
    exe.addCSourceFlag("-O3");
    
    // Enable debug info for profiling
    exe.addCSourceFlag("-g");
    
    // Link with math library
    exe.linkLibC();
    exe.linkSystemLibrary("m");
    exe.linkSystemLibrary("pthread");
    
    // Install the executable
    b.installArtifact(exe);
    
    // Create test step
    const exe_tests = b.addTest(.{
        .root_source_file = b.path("src/optimized_simulator.zig"),
        .target = target,
        .optimize = optimize,
    });
    
    // Add test dependencies
    exe_tests.linkLibC();
    exe_tests.linkSystemLibrary("m");
    exe_tests.linkSystemLibrary("pthread");
    
    const run_tests = b.addRunArtifact(exe_tests);
    
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);
    
    // Create benchmark step
    const bench_exe = b.addExecutable(.{
        .name = "voltedge-benchmark",
        .root_source_file = b.path("src/benchmarks.zig"),
        .target = target,
        .optimize = optimize,
    });
    
    bench_exe.linkLibC();
    bench_exe.linkSystemLibrary("m");
    bench_exe.linkSystemLibrary("pthread");
    
    const run_bench = b.addRunArtifact(bench_exe);
    
    const bench_step = b.step("bench", "Run performance benchmarks");
    bench_step.dependOn(&run_bench.step);
    
    // Create profiling step
    const profile_exe = b.addExecutable(.{
        .name = "voltedge-profile",
        .root_source_file = b.path("src/profile_main.zig"),
        .target = target,
        .optimize = .Debug, // Keep debug info for profiling
    });
    
    profile_exe.linkLibC();
    profile_exe.linkSystemLibrary("m");
    profile_exe.linkSystemLibrary("pthread");
    
    const run_profile = b.addRunArtifact(profile_exe);
    
    const profile_step = b.step("profile", "Run performance profiling");
    profile_step.dependOn(&run_profile.step);
    
    // Create run step with optimized executable
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    
    const run_step = b.step("run", "Run the optimized VoltEdge simulation engine");
    run_step.dependOn(&run_cmd.step);
}


