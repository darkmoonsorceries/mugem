/// Cocoa ObjC bindings for MUGEM
const std = @import("std");

// NSWindow style masks
pub const NSWindowStyleMask = struct {
    pub const borderless: u64 = 0;
    pub const titled: u64 = 1 << 0;
    pub const closable: u64 = 1 << 1;
    pub const miniaturizable: u64 = 1 << 2;
    pub const resizable: u64 = 1 << 3;
};

// NSBackingStoreType
pub const NSBackingStoreBuffered: u64 = 2;

// Simple NSRect
pub const NSRect = extern struct {
    x: f64,
    y: f64,
    width: f64,
    height: f64,
};

// NSPoint
pub const NSPoint = extern struct {
    x: f64,
    y: f64,
};

// NSSize  
pub const NSSize = extern struct {
    width: f64,
    height: f64,
};

extern "c" fn NSLog(format: [*c]const u8, ...) void;

/// Create window frame for 4x3 grid
pub fn calculateAgentFrame(agent_id: u8) NSRect {
    const col = (agent_id - 1) % 4;
    const row = (agent_id - 1) / 4;
    
    // Start at (100, 100) with 810x610 each (10px gap)
    return .{
        .x = 100.0 + @as(f64, @floatFromInt(col)) * 810.0,
        .y = 100.0 + @as(f64, @floatFromInt(row)) * 610.0,
        .width = 800.0,
        .height = 600.0,
    };
}

/// Create monitor window frame
pub fn calculateMonitorFrame() NSRect {
    return .{
        .x = 100.0,
        .y = 720.0 + 610.0, // Above agent grid
        .width = 800.0,
        .height = 400.0,
    };
}

test "frame calculation" {
    const frame1 = calculateAgentFrame(1);
    try std.testing.expectApproxEqAbs(frame1.x, 100.0, 0.01);
    try std.testing.expectApproxEqAbs(frame1.y, 100.0, 0.01);
    
    const frame12 = calculateAgentFrame(12);
    try std.testing.expectApproxEqAbs(frame12.x, 100.0 + 3.0 * 810.0, 0.01);
    try std.testing.expectApproxEqAbs(frame12.y, 100.0 + 2.0 * 610.0, 0.01);
}
