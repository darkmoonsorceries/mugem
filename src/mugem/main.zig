/// MUGEM - Multi Getsuga Universal Terminal
/// Entry point for the 12-agent bidirectional terminal
const std = @import("std");
const AgentWindow = @import("agent_window.zig").AgentWindow;
const AgentState = @import("agent_window.zig").AgentState;
const TawhidMode = @import("tawhid.zig").TawhidMode;
const DisplayProtocol = @import("tawhid.zig").DisplayProtocol;

const print = std.debug.print;

/// 12 active agent windows
var agents: [12]?*AgentWindow = .{null} ** 12;

/// Current display mode
var current_mode: TawhidMode = .mugetsu;

/// Unix socket for Python bridge
var socket_path: []const u8 = "/tmp/mugem.sock";

pub fn main() !void {
    print("MUGEM v1.0 - The Getsuga Tenshou Terminal\n", .{});
    print("Bismillah. Loading 12-agent swarm...\n\n", .{});
    
    // Parse args
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);
    
    // Check for --daemon or --single mode
    const daemon_mode = if (args.len > 1 and std.mem.eql(u8, args[1], "--daemon")) true else false;
    
    if (daemon_mode) {
        print("Daemon mode: Spawning 12 windows...\n", .{});
        try spawnAllAgents();
        print("All 12 agents ready.\n", .{});
        
        // Start Unix socket server for Python bridge
        try startSocketServer();
    } else {
        // Single window mode (for testing)
        print("Single window mode: Spawning agent-01...\n", .{});
        agents[0] = try AgentWindow.init(1, "kimi-01");
        agents[0].?.setState(.active);
        
        // Test bidirectional text
        const test_text = "Hello مرحبا World";
        agents[0].?.write(test_text);
        
        print("Press Enter to exit...", .{});
        _ = try std.io.getStdIn().reader().readByte();
    }
}

/// Spawn all 12 agent windows in 4x3 grid
fn spawnAllAgents() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    for (0..12) |i| {
        const id = @as(u8, i) + 1;
        const worktree = try std.fmt.allocPrint(allocator, "kimi-{d:02d}", .{id});
        defer allocator.free(worktree);
        
        print("  Spawning agent-{d:02d} at ", .{id});
        
        agents[i] = try AgentWindow.init(id, worktree);
        agents[i].?.setState(.active);
        
        // Initial status
        const status = try std.fmt.allocPrint(allocator, "Agent {d} initialized", .{id});
        defer allocator.free(status);
        agents[i].?.write(status);
    }
    
    // Create Zangetsu monitor (13th window)
    print("\nSpawning ZANGETSU monitor...\n", .{});
    try spawnMonitor();
}

/// Zangetsu monitor - shows all 12 agents
fn spawnMonitor() !void {
    _ = try AgentWindow.init(13, "zangetsu-monitor");
    // Special handling for monitor window
}

/// Unix socket server for Python bridge
fn startSocketServer() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Cleanup old socket
    std.fs.deleteFileAbsolute(socket_path) catch {};
    
    const address = try std.net.Address.initUnix(socket_path);
    var server = try address.listen(.{});
    defer server.deinit();
    
    print("\nSocket server listening on {s}\n", .{socket_path});
    print("Waiting for getsuga.py connections...\n\n", .{});
    
    while (true) {
        const conn = try server.accept();
        
        // Handle connection
        _ = std.Thread.spawn(.{}, handleConnection, .{conn}) catch |err| {
            print("Failed to spawn handler: {s}\n", .{@errorName(err)});
            conn.stream.close();
        };
    }
}

/// Handle Python bridge connection
fn handleConnection(conn: std.net.Server.Connection) void {
    var buf: [4096]u8 = undefined;
    const n = conn.stream.read(&buf) catch |err| {
        print("Read error: {s}\n", .{@errorName(err)});
        conn.stream.close();
        return;
    };
    
    const msg = buf[0..n];
    print("Received: {s}\n", .{msg});
    
    // Parse JSON command
    if (std.mem.startsWith(u8, msg, "{\"cmd\":\"spawn\"")) {
        // Extract agent_id from JSON
        if (std.mem.indexOf(u8, msg, "agent_id\":") != null) {
            // Parse and spawn
            print("Spawn request acknowledged\n", .{});
        }
    }
    
    // Send response
    const response = "{\"status\":\"ok\"}";
    _ = conn.stream.write(response) catch {};
    conn.stream.close();
}

/// Update agent state (called from socket handler)
pub fn updateAgentState(agent_id: u8, state: AgentState) void {
    if (agent_id < 1 or agent_id > 12) return;
    const idx = agent_id - 1;
    
    if (agents[idx]) |agent| {
        agent.setState(state);
        
        // Write to agent window
        const status_text = switch (state) {
            .active => "⚡ ACTIVE",
            .complete => "✓ COMPLETE",
            .failed => "✗ FAILED",
            .sealed => "◉ SEALED",
        };
        agent.write(status_text);
        
        // Update monitor
        updateMonitor();
    }
}

/// Refresh Zangetsu monitor display
fn updateMonitor() void {
    // Update the 13th window with current grid state
}

/// Set display mode dynamically (called from Python)
pub fn setMode(mode: TawhidMode) void {
    current_mode = mode;
    print("Mode changed to {s}\n", .{@tagName(mode)});
}
