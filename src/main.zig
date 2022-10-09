const std = @import("std");

const Errors = error{ BadTorrentFileStart, FieldSizeTooLarge, FieldSizeEmpty, UnexpectedlyShortValue, UnknownType };

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!general_purpose_allocator.deinit());
    const allocator = general_purpose_allocator.allocator();

    const file = try std.fs.cwd().openFile("ubuntu.torrent", .{});
    defer file.close();
    const reader = file.reader();

    const t = std.time.nanoTimestamp();
    try parse(allocator, reader);
    std.debug.print("total time: {}\n", .{std.time.nanoTimestamp() - t});
}

fn parse(allocator: std.mem.Allocator, reader: std.fs.File.Reader) anyerror!void {
    while (true) {
        const first = reader.readByte() catch return;
        switch (first) {
            '0'...'9' => { // 4:abcd
                const size_str = reader.readUntilDelimiterAlloc(allocator, ':', 10) catch |err| {
                    if (err == error.StreamTooLong) return Errors.FieldSizeTooLarge else return err;
                };
                defer allocator.free(size_str);
                const size_str_prefixed = try std.fmt.allocPrint(allocator, "{c}{s}", .{ first, size_str });
                defer allocator.free(size_str_prefixed);
                const size = try std.fmt.parseUnsigned(u32, size_str_prefixed, 10);

                const value_buffer = try allocator.alloc(u8, size);
                defer allocator.free(value_buffer);
                const value_size = try reader.readAll(value_buffer);
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
