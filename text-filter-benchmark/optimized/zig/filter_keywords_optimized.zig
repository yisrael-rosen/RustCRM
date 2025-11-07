const std = @import("std");

// רשימת 50 מילות מפתח לסינון תוכן בעברית
const KEYWORDS = [_][]const u8{
    // קטגוריה 1: תקשורת ומידע
    "שלום",
    "הודעה",
    "מידע",
    "עדכון",
    "התראה",
    "דיווח",
    "פרטים",
    "תיאור",
    "הסבר",
    "תוכן",

    // קטגוריה 2: פעולות עסקיות
    "רכישה",
    "מכירה",
    "עסקה",
    "הזמנה",
    "תשלום",
    "חשבונית",
    "הצעה",
    "חוזה",
    "הסכם",
    "דיל",

    // קטגוריה 3: סטטוס ומצב
    "מאושר",
    "ממתין",
    "בטיפול",
    "הושלם",
    "בוטל",
    "נדחה",
    "פעיל",
    "סגור",
    "פתוח",
    "חדש",

    // קטגוריה 4: לקוחות וקשרים
    "לקוח",
    "חברה",
    "איש קשר",
    "ספק",
    "שותף",
    "צוות",
    "מנהל",
    "משתמש",
    "משקיע",
    "יועץ",

    // קטגוריה 5: משימות ופעילות
    "משימה",
    "פגישה",
    "שיחה",
    "אימייל",
    "פעילות",
    "מעקב",
    "תזכורת",
    "יומן",
    "לוח",
    "תכנון",
};

const ChunkResult = struct {
    total_lines: usize,
    match_count: usize,
    output_size: usize,
    keyword_matches: [KEYWORDS.len]usize,
};

const WorkerContext = struct {
    chunk: []const u8,
    result: ChunkResult,
    allocator: std.mem.Allocator,
};

fn processChunk(context: *WorkerContext) void {
    var line_iter = std.mem.splitSequence(u8, context.chunk, "\n");
    var total_lines: usize = 0;
    var match_count: usize = 0;
    var output_size: usize = 0;
    var keyword_matches = [_]usize{0} ** KEYWORDS.len;

    while (line_iter.next()) |line| {
        total_lines += 1;
        var line_has_match = false;

        // Check each keyword
        for (KEYWORDS, 0..) |keyword, i| {
            var search_start: usize = 0;
            var occurrence_count: usize = 0;

            // Count all occurrences of keyword in line
            while (search_start < line.len) {
                if (std.mem.indexOf(u8, line[search_start..], keyword)) |pos| {
                    occurrence_count += 1;
                    search_start += pos + keyword.len;
                    if (!line_has_match) {
                        match_count += 1;
                        output_size += line.len + 1;
                        line_has_match = true;
                    }
                } else {
                    break;
                }
            }

            keyword_matches[i] += occurrence_count;
        }
    }

    context.result = ChunkResult{
        .total_lines = total_lines,
        .match_count = match_count,
        .output_size = output_size,
        .keyword_matches = keyword_matches,
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: {s} <input_file>\n", .{args[0]});
        std.debug.print("Searches for {d} Hebrew keywords in the file (parallel processing)\n", .{KEYWORDS.len});
        return error.InvalidArgs;
    }

    const input_path = args[1];

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
            .result = ChunkResult{
                .total_lines = 0,
                .match_count = 0,
                .output_size = 0,
                .keyword_matches = [_]usize{0} ** KEYWORDS.len,
            },
            .allocator = allocator,
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
    var keyword_matches = [_]usize{0} ** KEYWORDS.len;

    for (contexts) |context| {
        total_lines += context.result.total_lines;
        match_count += context.result.match_count;
        output_size += context.result.output_size;

        for (context.result.keyword_matches, 0..) |count, j| {
            keyword_matches[j] += count;
        }
    }

    // End timing
    const end_time = std.time.nanoTimestamp();
    const elapsed_ms = @divFloor(end_time - start_time, 1_000_000);

    // Print results
    std.debug.print("\n=== Zig Optimized Multi-Keyword Text Filter ===\n", .{});
    std.debug.print("Total keywords: {d}\n", .{KEYWORDS.len});
    std.debug.print("Total lines: {d}\n", .{total_lines});
    std.debug.print("Matching lines: {d}\n", .{match_count});
    std.debug.print("Time elapsed: {d}ms\n", .{elapsed_ms});
    std.debug.print("Output size: {d} bytes\n", .{output_size});
    std.debug.print("Workers used: {d}\n", .{num_workers});

    // Print keyword statistics
    std.debug.print("\n--- Keyword Matches ---\n", .{});
    var found_count: usize = 0;
    var total_keyword_matches: usize = 0;

    for (KEYWORDS, 0..) |keyword, j| {
        if (keyword_matches[j] > 0) {
            std.debug.print("  {s}: {d} matches\n", .{keyword, keyword_matches[j]});
            found_count += 1;
            total_keyword_matches += keyword_matches[j];
        }
    }

    std.debug.print("\n--- Summary ---\n", .{});
    std.debug.print("Unique keywords found: {d}/{d}\n", .{found_count, KEYWORDS.len});
    std.debug.print("Total keyword occurrences: {d}\n", .{total_keyword_matches});

    // Calculate performance metrics
    if (elapsed_ms > 0) {
        const elapsed_ms_usize: usize = @intCast(elapsed_ms);
        const lines_per_ms = total_lines / elapsed_ms_usize;
        const mb_size = @as(f64, @floatFromInt(file_size)) / (1024.0 * 1024.0);
        const throughput = mb_size / (@as(f64, @floatFromInt(elapsed_ms)) / 1000.0);
        std.debug.print("Processing speed: {d} lines/ms\n", .{lines_per_ms});
        std.debug.print("Throughput: {d:.2} MB/s\n", .{throughput});
    }
}
