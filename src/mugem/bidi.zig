// FriBidi / Bidirectional layout for Mugem
const std = @import("std");
const harfbuzz = @import("harfbuzz.zig");

/// Line segment by direction
pub const BidiRun = struct {
    text: []const u8,
    direction: harfbuzz.Direction,
    level: u8, // Embedding level
};

/// Split mixed-direction text into runs
pub fn splitBidi(allocator: std.mem.Allocator, text: []const u8) ![]BidiRun {
    // Simplified: scan for direction changes
    var runs = std.ArrayList(BidiRun).init(allocator);
    defer runs.deinit();
    
    var current_start: usize = 0;
    var current_dir = harfbuzz.detectDirection(text);
    
    var i: usize = 0;
    while (i < text.len) {
        const char_dir = detectCharDirection(text[i]);
        if (char_dir != current_dir and char_dir != .unset) {
            // Direction change
            try runs.append(BidiRun{
                .text = text[current_start..i],
                .direction = current_dir,
                .level = if (current_dir == .rtl) 1 else 0,
            });
            current_start = i;
            current_dir = char_dir;
        }
        i += 1;
    }
    
    // Final run
    try runs.append(BidiRun{
        .text = text[current_start..],
        .direction = current_dir,
        .level = if (current_dir == .rtl) 1 else 0,
    });
    
    return runs.toOwnedSlice();
}

fn detectCharDirection(c: u8) harfbuzz.Direction {
    if (c >= 0x0590 and c <= 0x08FF) return .rtl;
    if (c == 0x202E or c == 0x202D) return .rtl; // Explicit directional marks
    return .ltr;
}

/// Reorder runs for display (visual order)
pub fn visualOrder(runs: []BidiRun) []BidiRun {
    // LTR: runs in array order
    // RTL: reverse order of RTL runs
    // Mixed: complex bidi algorithm needed
    return runs; // Simplified for skeleton
}

/// Vertical layout for Japanese tategaki
pub const Tategaki = struct {
    pub fn layoutVertical(text: []const u8, allocator: std.mem.Allocator) ![]u32 {
        // Convert horizontal to vertical line
        var vertical = std.ArrayList(u32).init(allocator);
        defer vertical.deinit();
        
        for (text) |c| {
            // Rotate punctuation
            if (c == 0x3002 or c == 0xFF0E) { // 。
                // Period goes top-right in vertical
                try vertical.append(c + 0xFE00); // Variation selector
            } else {
                try vertical.append(c);
            }
        }
        
        return vertical.toOwnedSlice();
    }
};
