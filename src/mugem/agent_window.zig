const std = @import("std");
const c = @import("c");

pub const AgentState = enum {
    active,
    complete,
    failed,
    pending,
    sealed,
};

/// Agent window - one per agent in 4x3 grid
pub const AgentWindow = struct {
    id: u8,                    // 1-12
    worktree: []const u8,      // "kimi-01"
    window: *c.NSWindow,       // Cocoa window
    term: *TerminalSurface,     // Text surface
    
    pub fn init(id: u8, worktree: []const u8) !*AgentWindow {
        // Calculate 4x3 grid position
        const col = (id - 1) % 4;
        const row = (id - 1) / 4;
        
        const frame = c.NSRect{
            .x = 100 + @as(f64, @floatFromInt(col)) * 820,
            .y = 100 + @as(f64, @floatFromInt(row)) * 620,
            .width = 800,
            .height = 600,
        };
        
        // Create NSWindow
        const window = c.NSWindow_alloc_initWithContentRect_styleMask_backing_defer_(
            frame,
            c.NSWindowStyleMaskTitled | 
            c.NSWindowStyleMaskClosable | 
            c.NSWindowStyleMaskMiniaturizable |
            c.NSWindowStyleMaskResizable,
            c.NSBackingStoreBuffered,
            false,
        ) autorelease];
        
        const title = try std.fmt.allocPrintZ(std.heap.page_allocator, 
            "kimi-{d:02d} [AGENT-{d:02d}] — {s}", .{id, id, worktree});
        defer std.heap.page_allocator.free(title);
        
        window.setTitle_(c.NSString_stringWithUTF8String(title));
        window.makeKeyAndOrderFront_(null);
        
        // Create terminal surface
        const term = try TerminalSurface.alloc().init();
        window.setContentView_(term);
        
        const self = try std.heap.page_allocator.create(AgentWindow);
        self.* = .{
            .id = id,
            .worktree = worktree,
            .window = window,
            .term = term,
        };
        
        return self;
    }
    
    /// Set border color based on agent state
    pub fn setState(self: *AgentWindow, state: AgentState) void {
        const color: *c.NSColor = switch (state) {
            .active => c.NSColor_colorWithRed_green_blue_alpha_(
                0.0, 0.8, 0.2, 1.0),    // Green pulse
            .complete => c.NSColor_colorWithRed_green_blue_alpha_(
                0.9, 0.9, 0.9, 1.0),   // White
            .failed => c.NSColor_colorWithRed_green_blue_alpha_(
                0.9, 0.2, 0.2, 1.0),   // Red
            .sealed => c.NSColor_colorWithRed_green_blue_alpha_(
                0.5, 0.5, 0.5, 1.0),   // Gray
        };
        
        self.window.setBackgroundColor_(color);
        
        // Pulse animation for active
        if (state == .active) {
            c.CABasicAnimation_animationWithKeyPath_(
                c.NSString_stringWithUTF8String("backgroundColor"),
            );
        }
    }
    
    /// Write bidirectional text to this window
    pub fn write(self: *AgentWindow, text: []const u8) void {
        // Detect direction
        const dir = detectDirection(text);
        
        // Shape with HarfBuzz
        const shaped = self.term.shapeText(text, dir);
        
        // Render
        self.term.render(shaped);
    }
    
    pub fn deinit(self: *AgentWindow) void {
        self.window.close();
        self.term.release();
        std.heap.page_allocator.destroy(self);
    }
};

pub const Direction = enum {
    ltr,
    rtl,
    ttb,
};

fn detectDirection(text: []const u8) Direction {
    for (text) |c| {
        if (c >= 0x0590 and c <= 0x08FF) return .rtl;
        if (c >= 0x4E00 and c <= 0x9FFF) return .ttb;
    }
    return .ltr;
}
