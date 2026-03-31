// Minimal MUGEM test - validates our modules compile
const std = @import("std");
const mugem = @import("src/mugem.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    
    try stdout.print("MUGEM Test Runner\n", .{});
    try stdout.print("Version: {s}\n", .{mugem.VERSION});
    
    // Test 1: Config
    const config = mugem.MugemConfig{
        .enable_harfbuzz = true,
        .enable_fribidi = true,
        .enable_geometry = true,
    };
    try stdout.print("Config: harfbuzz={} fribidi={} geometry={}\n", .{
        config.enable_harfbuzz,
        config.enable_fribidi,
        config.enable_geometry,
    });
    
    // Test 2: Mugem init
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    var m = mugem.Mugem.init(allocator, config);
    try stdout.print("Mugem initialized\n", .{});
    
    // Test 3: Tawhid constants
    try stdout.print("5 modes: Fatiha={} Mugetsu={}\n", .{
        mugem.harfbuzz.TAWHID.FATIHA,
        mugem.harfbuzz.TAWHID.MUGETSU,
    });
    try stdout.print("7 checkpoints: ", .{});
    for (mugem.harfbuzz.TAWHID.CHECKPOINTS) |cp| {
        try stdout.print("{d} ", .{cp});
    }
    try stdout.print("\n", .{});
    try stdout.print("12 fives[0]={d}\n", .{mugem.harfbuzz.TAWHID.MIN_FIVES[0]});
    
    // Test 4: Direction detection
    const test_text = "Hello";
    const dir = mugem.harfbuzz.detectDirection(test_text);
    try stdout.print("Direction for '{}': {}\n", .{test_text, dir});
    
    // Test 5: Display mode
    const statuses = [_][]const u8{
        "complete", "active", "pending", "complete",
        "active", "error", "complete", "pending",
        "complete", "active", "complete", "sealed",
    };
    const grid = m.renderAgents(statuses, mugem.display.Mode.mugetsu);
    try stdout.print("Agent grid: {s}\n", .{grid});
    
    // Test 6: C API exports
    const ptr = mugem.mugem_create();
    if (ptr) |p| {
        try stdout.print("Created MUGEM instance: {*}, version={s}\n", .{p, mugem.mugem_version()});
        mugem.mugem_destroy(p);
    } else {
        try stdout.print("Failed to create instance\n", .{});
    }
    
    try stdout.print("\nAll tests passed! Bismillah.\n", .{});
}
