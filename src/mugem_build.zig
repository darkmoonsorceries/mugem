/// Build.zig additions for MUGEM module
/// Add these lines to main build.zig

const std = @import("std");

/// Use this function in your build.zig:
/// ```zig
/// const mugem_build = @import("src/mugem_build.zig");
/// mugem_build.addMugem(b, &deps, config);
/// ```
pub fn addMugem(
    b: *std.Build,
    deps: *anyopaque, // GhosttySharedDeps
    config: anyopaque, // GhosttyConfig
) !void {
    // Create mugem module
    const mugem_mod = b.createModule(.{
        .root_source_file = .{ .cwd_relative = "src/mugem/main.zig" },
        .target = config.target,
        .optimize = config.optimize,
    });
    
    // Add sub-modules
    const agent_window = b.createModule(.{
        .root_source_file = .{ .cwd_relative = "src/mugem/agent_window.zig" },
    });
    
    const bidi_mod = b.createModule(.{
        .root_source_file = .{ .cwd_relative = "src/mugem/bidi.zig" },
    });
    
    const display_mod = b.createModule(.{
        .root_source_file = .{ .cwd_relative = "src/mugem/display.zig" },
    });
    
    const harfbuzz_mod = b.createModule(.{
        .root_source_file = .{ .cwd_relative = "src/mugem/harfbuzz.zig" },
    });
    
    const tawhid_mod = b.createModule(.{
        .root_source_file = .{ .cwd_relative = "src/mugem/tawhid.zig" },
    });
    
    // Dependencies
    mugem_mod.addImport("agent_window", agent_window);
    mugem_mod.addImport("bidi", bidi_mod);
    mugem_mod.addImport("display", display_mod);
    mugem_mod.addImport("harfbuzz", harfbuzz_mod);
    mugem_mod.addImport("tawhid", tawhid_mod);
    
    // Link system libraries
    // HarfBuzz for text shaping
    mugem_mod.linkSystemLibrary("harfbuzz", .{
        .needed = true,
        .preferred_link_mode = .dynamic,
    });
    
    // FriBidi for bidirectional text
    mugem_mod.linkSystemLibrary("fribidi", .{
        .needed = true,
        .preferred_link_mode = .dynamic,
    });
    
    // ICU for Unicode data
    mugem_mod.linkSystemLibrary("icui18n", .{
        .needed = false,
        .preferred_link_mode = .dynamic,
    });
    
    // macOS frameworks
    if (config.target.result.os.tag.isDarwin()) {
        mugem_mod.linkFramework("Cocoa", .{});
        mugem_mod.linkFramework("Metal", .{});
        mugem_mod.linkFramework("MetalKit", .{});
        mugem_mod.linkFramework("QuartzCore", .{});
    }
    
    // Install mugem executable
    const mugem_exe = b.addExecutable(.{
        .name = "mugem",
        .root_module = mugem_mod,
    });
    
    b.installArtifact(mugem_exe);
    
    // Run step
    const run_cmd = b.addRunArtifact(mugem_exe);
    run_cmd.step.dependOn(b.getInstallStep());
    
    const run_step = b.step("mugem", "Run MUGEM terminal");
    run_step.dependOn(&run_cmd.step);
    
    // Test step
    const test_step = b.step("test-mugem", "Test MUGEM modules");
    
    const harfbuzz_test = b.addTest(.{
        .root_source_file = .{ .cwd_relative = "src/mugem/harfbuzz.zig" },
        .target = config.target,
        .optimize = config.optimize,
    });
    
    const bidi_test = b.addTest(.{
        .root_source_file = .{ .cwd_relative = "src/mugem/bidi.zig" },
        .target = config.target,
        .optimize = config.optimize,
    });
    
    const display_test = b.addTest(.{
        .root_source_file = .{ .cwd_relative = "src/mugem/display.zig" },
        .target = config.target,
        .optimize = config.optimize,
    });
    
    const tawhid_test = b.addTest(.{
        .root_source_file = .{ .cwd_relative = "src/mugem/tawhid.zig" },
        .target = config.target,
        .optimize = config.optimize,
    });
    
    test_step.dependOn(&b.addRunArtifact(harfbuzz_test).step);
    test_step.dependOn(&b.addRunArtifact(bidi_test).step);
    test_step.dependOn(&b.addRunArtifact(display_test).step);
    test_step.dependOn(&b.addRunArtifact(tawhid_test).step);
    
    // Print instructions
    const print_step = b.allocator.create(std.Build.Step) catch unreachable;
    print_step.* = std.Build.Step.init(.{
        .id = .custom,
        .name = "mugem-print",
        .make_fn = struct {
            fn make(step: *std.Build.Step, _: std.Progress.Node) anyerror!void {
                _ = step;
                std.log.info(
                    \\\n                    MUGEM Build Configuration:\n\
                    - Module: src/mugem/main.zig\n\
                    - Tests: zig build test-mugem\n\
                    - Run: zig build mugem\n\
                    - 12-agent grid: 4x3 layout\n\
                    \\
                , .{});
            }
        }.make,
        .owner = b,
    });
}
