// MUGEM: Multidirectional Getsuga Terminal
// The bidirectional, vertical, Tawhid-aware terminal module

const std = @import("std");
pub const harfbuzz = @import("mugem/harfbuzz.zig");
pub const bidi = @import("mugem/bidi.zig");
pub const display = @import("mugem/display.zig");

/// Version of Mugem (matches wahidOS)
pub const VERSION = "0.2.0-12worktrees";

pub const MugemConfig = struct {
    enable_harfbuzz: bool = true,
    enable_fribidi: bool = true,
    enable_geometry: bool = true, // Tawhid display modes
};

/// Main Mugem state
pub const Mugem = struct {
    config: MugemConfig,
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator, config: MugemConfig) Mugem {
        return .{
            .config = config,
            .allocator = allocator,
        };
    }
    
    /// Process a mixed-direction line
    pub fn processLine(self: *Mugem, text: []const u8, mode: display.Mode) ![]const u8 {
        if (mode == .mugetsu) {
            return text; // No processing in compressed mode
        }
        
        // Detect direction
        const dir = harfbuzz.detectDirection(text);
        
        if (dir == .rtl) {
            // Reverse for RTL display
            return try bidi.visualOrder(&.{.{
                .text = text,
                .direction = .rtl,
                .level = 1,
            }});
        }
        
        if (dir == .ttb) {
            // Convert to tategaki
            return try bidi.Tategaki.layoutVertical(text, self.allocator);
        }
        
        return text; // LTR default
    }
    
    /// Render 12-agent grid (the MUGEN pattern)
    pub fn renderAgents(self: *Mugem, statuses: [12][]const u8, mode: display.Mode) []const u8 {
        _ = self;
        return display.AgentGrid.render12(mode, statuses);
    }
};

/// Python bridge: C API for Python to call
export fn mugem_create() ?*Mugem {
    const allocator = std.heap.page_allocator;
    const mugem = allocator.create(Mugem) catch return null;
    mugem.* = Mugem.init(allocator, .{});
    return mugem;
}

export fn mugem_destroy(m: ?*Mugem) void {
    if (m) |ptr| {
        const allocator = ptr.allocator;
        allocator.destroy(ptr);
    }
}

export fn mugem_version() [*:0]const u8 {
    return VERSION;
}
