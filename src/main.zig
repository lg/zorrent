const std = @import("std");

const Errors = error{ BadTorrentFileStart, FieldSizeTooLarge, FieldSizeEmpty, UnexpectedlyShortValue, UnknownType };

pub fn main() !void {
    var heap_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer heap_allocator.deinit();
    //var heap_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    //defer std.debug.assert(!heap_allocator.deinit());
    const allocator = heap_allocator.allocator();

    const file = try std.fs.cwd().openFile("ubuntu.torrent", .{});
    defer file.close();
    const reader = file.reader();

    const t = std.time.nanoTimestamp();
    try parse(allocator, reader);

    std.debug.print("total timez: {}\n", .{std.time.nanoTimestamp() - t});
}

fn parse(allocator: std.mem.Allocator, reader: std.fs.File.Reader) !void {
    while (true) {
        const first = reader.readByte() catch return;
        switch (first) {
            '0'...'9' => { // 4:abcd
                const size_str_second_part = try reader.readUntilDelimiterAlloc(allocator, ':', 10);
                defer allocator.free(size_str_second_part);

                const size_str = try std.mem.concat(allocator, u8, &[_][]u8{ &[_]u8{first}, size_str_second_part });
                defer allocator.free(size_str);

                const size = try std.fmt.parseUnsigned(u32, size_str, 10);
                const value_buffer = try allocator.alloc(u8, size);
                defer allocator.free(value_buffer);
                const value_size = try reader.readAll(value_buffer); // reads up to the size of the buffer
                if (value_size != size) return Errors.UnexpectedlyShortValue;

                if (size <= 50) std.debug.print("{s}\n", .{value_buffer}) else std.debug.print("[text of length {}]\n", .{size});
            },
            'i' => {
                const num_str = try reader.readUntilDelimiterAlloc(allocator, 'e', 20);
                defer allocator.free(num_str);
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
                std.debug.print("unknown type: {c}\n", .{first});
                unreachable;
            },
        }
    }
}

// var i: usize = 0;
// while (i < indent) : (i += 1) std.debug.print(" ", .{});
// std.debug.print("<start dictionary>\n", .{});
// indent += 2;

test "basic test" {
    @breakpoint();
    try std.testing.expectEqual(10, 3 + 7);
}
