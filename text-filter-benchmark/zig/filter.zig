const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 3) {
        std.debug.print("Usage: {s} <input_file> <search_pattern>\n", .{args[0]});
        return error.InvalidArgs;
    }

    const input_path = args[1];
    const pattern = args[2];

    // Start timing
    const start_time = std.time.nanoTimestamp();

    // Open input file
    const file = try std.fs.cwd().openFile(input_path, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const content = try file.readToEndAlloc(allocator, file_size);
    defer allocator.free(content);

    // Filter lines
    var line_iter = std.mem.splitSequence(u8, content, "\n");
    var match_count: usize = 0;
    var total_lines: usize = 0;
    var output_size: usize = 0;

    while (line_iter.next()) |line| {
        total_lines += 1;
        if (std.mem.indexOf(u8, line, pattern) != null) {
            match_count += 1;
            output_size += line.len + 1; // +1 for newline
        }
    }

    // End timing
    const end_time = std.time.nanoTimestamp();
    const elapsed_ms = @divFloor(end_time - start_time, 1_000_000);

    // Print results
    std.debug.print("\n=== Zig Text Filter ===\n", .{});
    std.debug.print("Total lines: {d}\n", .{total_lines});
    std.debug.print("Matching lines: {d}\n", .{match_count});
    std.debug.print("Time elapsed: {d}ms\n", .{elapsed_ms});
    std.debug.print("Output size: {d} bytes\n", .{output_size});
}
