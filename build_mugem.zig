const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    
    // MUGEM daemon executable
    const exe = b.addExecutable(.{
        .name = "mugem",
        .root_source_file = b.path("src/mugem/main_real.zig"),
        .target = target,
        .optimize = optimize,
    });
    
    // Link system libraries
    exe.linkSystemLibrary("c");
    exe.linkFramework("Cocoa");
    exe.linkFramework("Metal");
    exe.linkFramework("MetalKit");
    exe.linkFramework("QuartzCore");
    
    // Link HarfBuzz/FriBidi if available
    exe.linkSystemLibrary("harfbuzz");
    exe.linkSystemLibrary("fribidi");
    
    // Add include paths
    exe.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include" });
    exe.addIncludePath(.{ .cwd_relative = "/usr/local/include" });
    
    // Library paths
    exe.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib" });
    exe.addLibraryPath(.{ .cwd_relative = "/usr/local/lib" });
    
    b.installArtifact(exe);
    
    // Run step
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run-mugem", "Run MUGEM daemon");
    run_step.dependOn(&run_cmd.step);
    
    // Test step
    const test_step = b.step("test-mugem", "Test MUGEM modules");
    
    const modules = [_][]const u8{
        "src/mugem/harfbuzz.zig",
        "src/mugem/bidi.zig", 
        "src/mugem/display.zig",
        "src/mugem/tawhid.zig",
        "src/mugem/agent_window_real.zig",
        "src/mugem/cocoa.zig",
    };
    
    for (modules) |mod| {
        const t = b.addTest(.{
            .root_source_file = b.path(mod),
            .target = target,
            .optimize = optimize,
        });
        test_step.dependOn(&t.step);
    }
}
