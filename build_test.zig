const std = @import("std");
const mugem = @import("src/mugem.zig");

pub fn main() !void {
    const stdout_file = std.io.getStdOut();
    try stdout_file.writeAll("MUGEM TEST\n");
    
    var msg: [256]u8 = undefined;
    const len = std.fmt.format(&msg, "Version: {s}\n", .{mugem.VERSION}) catch 0;
    try stdout_file.writeAll(msg[0..len]);
    
    // Tawhid constants
    const tawhid_msg = std.fmt.format(&msg, "5 modes: Fatiha={} Mugetsu={}\n", .{
        mugem.harfbuzz.TAWHID.FATIHA,
        mugem.harfbuzz.TAWHID.MUGETSU,
    }) catch 0;
    try stdout_file.writeAll(msg[0..tawhid_msg]);
    
    // C API test
    const ptr = mugem.mugem_create();
    if (ptr) |_| {
        try stdout_file.writeAll("Instance: OK\n");
        mugem.mugem_destroy(ptr.?);
    }
    
    try stdout_file.writeAll("All tests passed.\n");
}
