const std = @import("std");

const Errors = error{ UnknownType, BadStringLength };

pub fn main() !void {
    // var heap_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // defer heap_allocator.deinit();
    var heap_allocator = std.heap.GeneralPurposeAllocator(.{}){}; // so we can check for memory leaks
    defer std.debug.assert(!heap_allocator.deinit());
    const allocator = heap_allocator.allocator();

    const file = try std.fs.cwd().openFile("ubuntu.torrent", .{});
    defer file.close();

    const file_stat = try file.stat();
    const data = try file.readToEndAlloc(allocator, file_stat.size);
    defer allocator.free(data);

    const t = std.time.nanoTimestamp();
    try parse(allocator, data);
    std.debug.print("total timez: {}\n", .{std.time.nanoTimestamp() - t});
}

fn parse(_: std.mem.Allocator, data: []const u8) !void {
    var index: usize = 0;

    while (index < data.len) : (index += 1) {
        const curChar = data[index];

        switch (curChar) {
            '0'...'9' => { // 4:abcd
                const colon_index = std.mem.indexOfPos(u8, data, index, &[_]u8{':'}) orelse return Errors.BadStringLength;
                const size_str = data[index..colon_index];
                const size: u32 = try std.fmt.parseUnsigned(u32, size_str, 10);
                index = colon_index + size;
                const value = data[(colon_index + 1) .. index + 1];

                if (size <= 50) std.debug.print("{s}\n", .{value}) else std.debug.print("[text of length {}]\n", .{size});
            },
            'i' => { // i12345e
                const end_index = std.mem.indexOfPos(u8, data, index, &[_]u8{'e'}) orelse return Errors.BadStringLength;
                const num_str = data[index + 1 .. end_index];
                index = end_index;
                std.debug.print("{s}\n", .{num_str});
            },
            'd' => {
                std.debug.print("<start dictionary>\n", .{});
            },
            'l' => {
                std.debug.print("<start list>\n", .{});
            },
            'e' => {
                std.debug.print("<end>\n", .{});
            },
            else => {
                std.debug.print("unknown type: {c}\n", .{curChar});
                return Errors.UnknownType;
            },
        }
    }
}
