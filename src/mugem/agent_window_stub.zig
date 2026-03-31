/// STUB: Agent window for compilation testing
/// Real implementation needs Cocoa bindings
const std = @import("std");

pub const AgentState = enum {
    active,
    complete,
    failed,
    pending,
    sealed,
};

pub const Direction = enum {
    ltr,
    rtl,
    ttb,
};

/// Placeholder AgentWindow - replaces Cocoa-dependent version
pub const AgentWindow = struct {
    id: u8,
    worktree: []const u8,
    state: AgentState = .pending,
    
    pub fn init(id: u8, worktree: []const u8) !*AgentWindow {
        const self = try std.heap.page_allocator.create(AgentWindow);
        self.* = .{
            .id = id,
            .worktree = try std.heap.page_allocator.dupe(u8, worktree),
        };
        std.log.info("AgentWindow {d} ({s}) created", .{id, worktree});
        return self;
    }
    
    pub fn setState(self: *AgentWindow, state: AgentState) void {
        self.state = state;
        const status = switch (state) {
            .active => "⚡ ACTIVE",
            .complete => "✓ COMPLETE",
            .failed => "✗ FAILED",
            .pending => "⏳ PENDING",
            .sealed => "◉ SEALED",
        };
        std.log.info("Agent {d}: {s}", .{self.id, status});
    }
    
    pub fn write(self: *AgentWindow, text: []const u8) void {
        std.log.info("Agent {d} output: {s}", .{self.id, text});
        _ = text;
    }
    
    pub fn deinit(self: *AgentWindow) void {
        std.heap.page_allocator.free(self.worktree);
        std.heap.page_allocator.destroy(self);
    }
};

fn detectDirection(text: []const u8) Direction {
    for (text) |ch| {
        if (ch >= 0x0590 and ch <= 0x08FF) return .rtl;
        if (ch >= 0x4E00 and ch <= 0x9FFF) return .ttb;
    }
    return .ltr;
}

test "AgentState enum" {
    try std.testing.expectEqual(5, @intFromEnum(AgentState.sealed) + 1);
}

test "AgentWindow lifecycle" {
    const agent = try AgentWindow.init(1, "kimi-01");
    agent.setState(.active);
    agent.write("Hello");
    agent.setState(.complete);
    agent.deinit();
}
