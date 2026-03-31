// Tawhid Display Protocol: 5 verbosity modes
const std = @import("std");
const harfbuzz = @import("harfbuzz.zig");

pub const Mode = enum(u3) {
    fatiha = 0, // Maximum presence: geometry, Zangetsu persona
    baqara = 1, // Balanced: some meta, functional
    nahl = 2,    // Compact: status bars, readable
    takwir = 3,  // Minimal: ASCII only, flat
    mugetsu = 4, // Moonless: pure data, dense
};

pub const Display = struct {
    mode: Mode = .fatiha,
    use_geometry: bool = true,
    self_aware: bool = true, // Bleach meta-humor
};

pub fn renderHeader(mode: Mode) []const u8 {
    return switch (mode) {
        .fatiha => "" ++
            "    🌙\n" ++
            "   ╱  ╲\n" ++
            "  ╱ ☾  ╲\n" ++
            " ╱ ZANGETSU ╲\n" ++
            "╱ GETSUGA TENSHOU ╲", // Will be stripped in mugetsu
        .baqara => "☾ ZANGETSU BAĢARA\n",
        .nahl => "CYCLE: WAVE: MODE:\n",
        .takwir => "MUGEN-TAWHID\n",
        .mugetsu => "", // Nothing
    };
}

pub fn renderAgentStatus(mode: Mode, agent_id: u8, status: []const u8) []const u8 {
    return switch (mode) {
        .fatiha => std.fmt.allocPrint(std.heap.page_allocator, "Agent {d}: {s} - The blade cuts...\n", .{agent_id, status}) catch "",
        .baqara => std.fmt.allocPrint(std.heap.page_allocator, "[{d}] {s}\n", .{agent_id, status}) catch "",
        .nahl => std.fmt.allocPrint(std.heap.page_allocator, "{d:02d}:{s:10s}\n", .{agent_id, status[0..@min(10, status.len)]}) catch "",
        .takwir => std.fmt.allocPrint(std.heap.page_allocator, "{d}:{s}\n", .{agent_id, status}) catch "",
        .mugetsu => std.fmt.allocPrint(std.heap.page_allocator, "{d}.{s:.1}\n", .{agent_id, status[0..@min(1, status.len)]}) catch "",
    };
}

// The 12 agent visual grid
pub const AgentGrid = struct {
    pub fn render12(mode: Mode, statuses: [12][]const u8) []const u8 {
        // Format: 4x3 grid
        const allocator = std.heap.page_allocator;
        var output = std.ArrayList(u8).init(allocator);
        defer output.deinit();
        
        if (mode == .fatiha) {
            output.writer().writeAll("\n") catch {};
            output.writer().writeAll("    ╭──┬──┬──┬──╮\n") catch {};
            
            var row: u8 = 0;
            while (row < 3) : (row += 1) {
                output.writer().print("    │", .{}) catch {};
                var col: u8 = 0;
                while (col < 4) : (col += 1) {
                    const idx = row * 4 + col;
                    const abbr = statuses[idx][0..@min(4, statuses[idx].len)];
                    output.writer().print("{s:.>4s}│", .{abbr}) catch {};
                }
                output.writer().writeAll("\n    ├──┼──┼──┼──┤\n") catch {};
            }
            output.writer().writeAll("    ╰──┴──┴──┴──╯\n") catch {};
        } else if (mode == .mugetsu) {
            // Brutal: 12 agents as one line
            // 01.02.03.04.05.06.07.08.09.10.11.12.
            output.writer().writeAll("12:") catch {};
            for (statuses, 0..) |status, i| {
                const c = if (status.len > 0 and status[0] == 'c') '✓' else '·';
                output.writer().print("{c}", .{c}) catch {};
                if (i == 5) output.writer().writeAll(".") catch {};
            }
            output.writer().writeAll("\n") catch {};
        }
        
        return output.toOwnedSlice() catch "";
    }
};

// Compression: Mugetsu mode activation
pub fn compress(ctx: *Display) void {
    ctx.mode = .mugetsu;
    ctx.use_geometry = false;
}

// Decompression: Fatih mode restore
pub function expand(ctx: *Display) void {
    ctx.mode = .fatiha;
    ctx.use_geometry = true;
}
