const std = @import("std");

const ChunkResult = struct {
    total_lines: usize,
    match_count: usize,
    output_size: usize,
};

const WorkerContext = struct {
    chunk: []const u8,
    pattern: []const u8,
    result: ChunkResult,
};

fn processChunk(context: *WorkerContext) void {
    var line_iter = std.mem.splitSequence(u8, context.chunk, "\n");
    var total_lines: usize = 0;
    var match_count: usize = 0;
    var output_size: usize = 0;

    while (line_iter.next()) |line| {
        total_lines += 1;
        if (std.mem.indexOf(u8, line, context.pattern) != null) {
            match_count += 1;
            output_size += line.len + 1;
        }
    }

    context.result = ChunkResult{
        .total_lines = total_lines,
        .match_count = match_count,
        .output_size = output_size,
    };
}

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

    // Read entire file
    const file = try std.fs.cwd().openFile(input_path, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const content = try file.readToEndAlloc(allocator, file_size);
    defer allocator.free(content);

    // Get CPU count for optimal parallelism
    const cpu_count = try std.Thread.getCpuCount();
    const num_workers = @min(cpu_count, 8); // Cap at 8 threads

    // Calculate chunk size
    const chunk_size = content.len / num_workers;

    // Create worker contexts
    var contexts = try allocator.alloc(WorkerContext, num_workers);
    defer allocator.free(contexts);

    var threads = try allocator.alloc(std.Thread, num_workers);
    defer allocator.free(threads);

    // Split work into chunks and spawn threads
    var i: usize = 0;
    while (i < num_workers) : (i += 1) {
        const start = i * chunk_size;
        const end = if (i == num_workers - 1) content.len else (i + 1) * chunk_size;

        contexts[i] = WorkerContext{
            .chunk = content[start..end],
            .pattern = pattern,
            .result = ChunkResult{ .total_lines = 0, .match_count = 0, .output_size = 0 },
        };

        threads[i] = try std.Thread.spawn(.{}, processChunk, .{&contexts[i]});
    }

    // Wait for all threads to complete
    for (threads) |thread| {
        thread.join();
    }

    // Aggregate results
    var total_lines: usize = 0;
    var match_count: usize = 0;
    var output_size: usize = 0;

    for (contexts) |context| {
        total_lines += context.result.total_lines;
        match_count += context.result.match_count;
        output_size += context.result.output_size;
    }

    // End timing
    const end_time = std.time.nanoTimestamp();
    const elapsed_ms = @divFloor(end_time - start_time, 1_000_000);

    // Print results
    std.debug.print("\n=== Zig Optimized Text Filter ===\n", .{});
    std.debug.print("Total lines: {d}\n", .{total_lines});
    std.debug.print("Matching lines: {d}\n", .{match_count});
    std.debug.print("Time elapsed: {d}ms\n", .{elapsed_ms});
    std.debug.print("Output size: {d} bytes\n", .{output_size});
    std.debug.print("Workers used: {d}\n", .{num_workers});
}
