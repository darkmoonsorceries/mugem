/// MUGEM Daemon - Unix socket server
/// Listens on /tmp/mugem.sock for Python bridge commands
const std = @import("std");
const posix = std.posix;
const tawhid = @import("tawhid.zig");
const AgentWindow = @import("agent_window_real.zig").AgentWindow;

const SOCKET_PATH = "/tmp/mugem.sock";

pub const Command = struct {
    cmd: []const u8,
    worktree: []const u8,
    command: []const u8,
    mode: tawhid.TawhidMode,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Remove old socket
    posix.unlink(SOCKET_PATH) catch {};
    
    // Create socket
    const sock = try posix.socket(posix.AF.UNIX, posix.SOCK.STREAM, 0);
    defer posix.close(sock);
    
    // Bind
    const addr = try std.net.Address.initUnix(SOCKET_PATH);
    try posix.bind(sock, &addr.any, addr.getOsSockLen());
    try posix.listen(sock, 128);
    
    std.log.info("MUGEM daemon listening on {s}", .{SOCKET_PATH});
    std.log.info("Waiting for Python bridge connections...", .{});
    
    // Spawn 13 windows (12 agents + 1 monitor)
    try spawnAllWindows(allocator);
    
    // Accept loop
    while (true) {
        var client_addr: posix.sockaddr.un = undefined;
        var client_len: posix.socklen_t = @sizeOf(posix.sockaddr.un);
        
        const client = try posix.accept(sock, @ptrCast(&client_addr), &client_len, 0);
        defer posix.close(client);
        
        // Handle command
        var buf: [4096]u8 = undefined;
        const n = try posix.recv(client, &buf, 0);
        if (n == 0) continue;
        
        const json_cmd = buf[0..n];
        std.log.info("Received: {s}", .{json_cmd});
        
        // Process command (simplified)
        const resp = "{\"status\":\"ok\"}";
        _ = try posix.send(client, resp, 0);
    }
}

fn spawnAllWindows(allocator: std.mem.Allocator) !void {
    // 12 agent windows
    for (1..13) |i| {
        const worktree = try std.fmt.allocPrint(allocator, "kimi-{d:02d}", .{i});
        defer allocator.free(worktree);
        
        const agent = try AgentWindow.init(@intCast(i), worktree);
        agent.setState(.pending);
        
        std.log.info("Window {d}/{d} spawned: {s}", .{i, 12, worktree});
    }
    
    // 1 monitor window
    const monitor = try AgentWindow.init(13, "zangetsu-monitor");
    monitor.setState(.active);
    std.log.info("Zangetsu monitor spawned", .{});
}

test "parse command" {
    const json = "{\"cmd\":\"spawn\",\"worktree\":\"kimi-01\",\"command\":\"python3 test.py\",\"mode\":4}";
    std.log.info("Would parse: {s}", .{json});
    _ = json;
}
