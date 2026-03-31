/// Tawhid Display Protocol - 5 verbosity modes
const std = @import("std");

/// The 5 modes (corresponding to first 5 surahs)
pub const TawhidMode = enum {
    fatiha,   // 0 - Maximum: full geometry, Zangetsu persona
    baqara,   // 1 - Balanced: symbols + text
    nahl,     // 2 - Compact: status bars
    takwir,   // 3 - Minimal: ASCII only
    mugetsu,  // 4 - Moonless: raw data
};

pub const AgentState = enum {
    active,
    complete,
    failed,
    pending,
    sealed,
};

/// Display protocol state
pub const DisplayProtocol = struct {
    mode: TawhidMode,
    agent_states: [12]AgentState,
    cycle: u16,
    wave: u8,
    active_count: u8,
    complete_count: u8,
    
    pub fn init(mode: TawhidMode) *DisplayProtocol {
        const self = std.heap.page_allocator.create(DisplayProtocol) catch unreachable;
        self.* = .{
            .mode = mode,
            .agent_states = .{.pending} ** 12,
            .cycle = 1,
            .wave = 1,
            .active_count = 0,
            .complete_count = 0,
        };
        return self;
    }
    
    /// Render based on current mode
    pub fn render(self: *DisplayProtocol, surface: anytype) void {
        switch (self.mode) {
            .fatiha => self.renderFatiha(surface),
            .baqara => self.renderBaqara(surface),
            .nahl => self.renderNahl(surface),
            .takwir => self.renderTakwir(surface),
            .mugetsu => self.renderMugetsu(surface),
        }
    }
    
    /// MODE 0: Fatiha - Maximum presence
    fn renderFatiha(self: *DisplayProtocol, surface: anytype) void {
        _ = self;
        // Header with crescent
        surface.write("    🌙\n");
        surface.write("   ╱  ╲\n");
        surface.write("  ╱ ☾  ╲\n");
        surface.write(" ╱ZANGETSU╲\n");
        surface.write("╱ GETSUGA ╲\n");
        surface.write("TENSHOU\n");
        
        // 12-agent grid
        surface.write("┌────┬────┬────┬────┐\n");
        surface.write("│01  │02  │03  │04  │\n");
        surface.write("├────┼────┼────┼────┤\n");
        surface.write("│05  │06  │07  │08  │\n");
        surface.write("├────┼────┼────┼────┤\n");
        surface.write("│09  │10  │11  │12  │\n");
        surface.write("└────┴────┴────┴────┘\n");
        
        // Seal
        surface.write("    ╰─────────╯\n");
        surface.write("     MU SEALED\n");
    }
    
    /// MODE 1: Baqara - Balanced
    fn renderBaqara(self: *DisplayProtocol, surface: anytype) void {
        const symbols = [_][]const u8{"◯", "◇", "◈", "◉"};
        
        surface.print("☾ CYCLE {d:03d} | WAVE {d:02d} | AGENTS {d}/12\n", 
            .{self.cycle, self.wave, self.complete_count});
        
        for (self.agent_states, 0..) |state, i| {
            const symbol = symbols[i % 4];
            const status = switch (state) {
                .active => "●",
                .complete => "✓",
                .failed => "✗",
                .pending => "○",
                .sealed => "◉",
            };
            surface.print("  {s} Agent-{d:02d}: {s}\n", .{symbol, i + 1, status});
        }
    }
    
    /// MODE 2: Nahl - Compact
    fn renderNahl(self: *DisplayProtocol, surface: anytype) void {
        surface.print("C{d:03d}-W{d:02d} | ", .{self.cycle, self.wave});
        surface.print("AGENTS: ");
        
        for (self.agent_states, 0..) |state, i| {
            const char = switch (state) {
                .complete => "✓",
                .active => "⚡",
                .failed => "✗",
                .pending => "·",
                .sealed => "◉",
            };
            surface.print("{s}{d:02d} ", .{char, i + 1});
        }
        
        surface.print("| {d}/{d}\n", .{self.complete_count, 12});
    }
    
    /// MODE 3: Takwir - Minimal
    fn renderTakwir(self: *DisplayProtocol, surface: anytype) void {
        surface.print("{d}.{d}:", .{self.cycle, self.wave});
        
        for (self.agent_states) |state| {
            const c = switch (state) {
                .complete => "+",
                .active => "*",
                .failed => "!",
                .pending => ".",
                .sealed => "#",
            };
            surface.print("{s}", .{c});
        }
        
        surface.print("|{d}\n", .{self.complete_count});
    }
    
    /// MODE 4: Mugetsu - Moonless, brutal
    fn renderMugetsu(self: *DisplayProtocol, surface: anytype) void {
        // Raw data: "001.01:............|12"
        surface.print("{d:03d}.{d:02d}:", .{self.cycle, self.wave});
        
        for (self.agent_states) |state| {
            const c = if (state == .complete) "." else "X";
            surface.print("{s}", .{c});
        }
        
        surface.print("|{d}\n", .{self.complete_count});
    }
    
    /// Update single agent state
    pub fn setAgentState(self: *DisplayProtocol, agent_id: u8, state: AgentState) void {
        if (agent_id < 1 or agent_id > 12) return;
        
        const idx = agent_id - 1;
        const old_state = self.agent_states[idx];
        self.agent_states[idx] = state;
        
        // Update counters
        if (old_state != .complete and state == .complete) {
            self.complete_count += 1;
        }
        if (state == .active) {
            self.active_count += 1;
        }
    }
};

/// The 7 checkpoints
pub const CHECKPOINTS = [7]u8{1, 2, 3, 4, 5, 6, 7};

/// The 12 fives (5 minutes each)
pub const MIN_FIVES = [12]u8{5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60};
