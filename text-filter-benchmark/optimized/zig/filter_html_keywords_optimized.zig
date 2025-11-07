const std = @import("std");

// HTML Parser embedded
const HtmlParser = struct {
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator) HtmlParser {
        return HtmlParser{ .allocator = allocator };
    }

    fn extractText(self: *const HtmlParser, html: []const u8) ![]u8 {
        var result = std.ArrayList(u8).init(self.allocator);
        errdefer result.deinit();

        var i: usize = 0;
        var in_tag = false;
        var in_script = false;
        var in_style = false;
        var last_was_space = false;

        while (i < html.len) {
            const ch = html[i];

            if (ch == '<') {
                in_tag = true;

                if (i + 7 < html.len and std.mem.eql(u8, html[i .. i + 7], "<script")) {
                    in_script = true;
                } else if (i + 6 < html.len and std.mem.eql(u8, html[i .. i + 6], "<style")) {
                    in_style = true;
                } else if (i + 9 < html.len and std.mem.eql(u8, html[i .. i + 9], "</script>")) {
                    in_script = false;
                    i += 8;
                } else if (i + 8 < html.len and std.mem.eql(u8, html[i .. i + 8], "</style>")) {
                    in_style = false;
                    i += 7;
                }
                i += 1;
                continue;
            }

            if (ch == '>') {
                in_tag = false;
                if (result.items.len > 0 and !last_was_space) {
                    try result.append(' ');
                    last_was_space = true;
                }
                i += 1;
                continue;
            }

            if (in_tag or in_script or in_style) {
                i += 1;
                continue;
            }

            if (std.ascii.isWhitespace(ch)) {
                if (!last_was_space and result.items.len > 0) {
                    try result.append(' ');
                    last_was_space = true;
                }
                i += 1;
                continue;
            }

            try result.append(ch);
            last_was_space = false;
            i += 1;
        }

        return result.toOwnedSlice();
    }
};

// רשימת 50 מילות מפתח לסינון תוכן בעברית
const KEYWORDS = [_][]const u8{
    // קטגוריה 1: תקשורת ומידע
    "שלום",     "הודעה",   "מידע",    "עדכון",   "התראה",
    "דיווח",    "פרטים",   "תיאור",   "הסבר",    "תוכן",
    // קטגוריה 2: פעולות עסקיות
    "רכישה",    "מכירה",   "עסקה",    "הזמנה",   "תשלום",
    "חשבונית",  "הצעה",    "חוזה",    "הסכם",    "דיל",
    // קטגוריה 3: סטטוס ומצב
    "מאושר",    "ממתין",   "בטיפול", "הושלם",   "בוטל",
    "נדחה",     "פעיל",    "סגור",    "פתוח",    "חדש",
    // קטגוריה 4: לקוחות וקשרים
    "לקוח",     "חברה",    "איש קשר", "ספק",     "שותף",
    "צוות",     "מנהל",    "משתמש",   "משקיע",   "יועץ",
    // קטגוריה 5: משימות ופעילות
    "משימה",    "פגישה",   "שיחה",    "אימייל",  "פעילות",
    "מעקב",     "תזכורת",  "יומן",    "לוח",     "תכנון",
};

const ProcessResult = struct {
    keyword_matches: [KEYWORDS.len]usize,
    total_matches: usize,
};

const WorkerContext = struct {
    text_chunk: []const u8,
    result: ProcessResult,
};

fn processTextChunk(context: *WorkerContext) void {
    var keyword_matches = [_]usize{0} ** KEYWORDS.len;
    var total_matches: usize = 0;

    for (KEYWORDS, 0..) |keyword, i| {
        var search_start: usize = 0;
        var count: usize = 0;

        while (search_start < context.text_chunk.len) {
            if (std.mem.indexOf(u8, context.text_chunk[search_start..], keyword)) |pos| {
                count += 1;
                search_start += pos + keyword.len;
            } else {
                break;
            }
        }

        keyword_matches[i] = count;
        total_matches += count;
    }

    context.result = ProcessResult{
        .keyword_matches = keyword_matches,
        .total_matches = total_matches,
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: {s} <input_file.html>\n", .{args[0]});
        std.debug.print("Filters HTML file for {d} Hebrew keywords (optimized parallel version)\n", .{KEYWORDS.len});
        return error.InvalidArgs;
    }

    const input_path = args[1];

    // Start timing
    const start_time = std.time.nanoTimestamp();

    // Read HTML file
    const file = try std.fs.cwd().openFile(input_path, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const html_content = try file.readToEndAlloc(allocator, file_size);
    defer allocator.free(html_content);

    // Parse HTML and extract text
    const parse_start = std.time.nanoTimestamp();
    const parser = HtmlParser.init(allocator);
    const text_content = try parser.extractText(html_content);
    defer allocator.free(text_content);
    const parse_end = std.time.nanoTimestamp();
    const parse_time_ms = @divFloor(parse_end - parse_start, 1_000_000);

    // Get CPU count for optimal parallelism
    const cpu_count = try std.Thread.getCpuCount();
    const num_workers = @min(cpu_count, 8);

    // For small texts, use single-threaded approach
    if (text_content.len < 10000 or num_workers == 1) {
        var context = WorkerContext{
            .text_chunk = text_content,
            .result = ProcessResult{
                .keyword_matches = [_]usize{0} ** KEYWORDS.len,
                .total_matches = 0,
            },
        };
        processTextChunk(&context);

        const end_time = std.time.nanoTimestamp();
        const elapsed_ms = @divFloor(end_time - start_time, 1_000_000);

        printResults(input_path, file_size, text_content.len, parse_time_ms, elapsed_ms, 1, context.result.keyword_matches, context.result.total_matches, text_content);
        return;
    }

    // Parallel processing for larger texts
    const chunk_size = text_content.len / num_workers;

    var contexts = try allocator.alloc(WorkerContext, num_workers);
    defer allocator.free(contexts);

    var threads = try allocator.alloc(std.Thread, num_workers);
    defer allocator.free(threads);

    // Spawn worker threads
    var i: usize = 0;
    while (i < num_workers) : (i += 1) {
        const start = i * chunk_size;
        const end = if (i == num_workers - 1) text_content.len else (i + 1) * chunk_size;

        contexts[i] = WorkerContext{
            .text_chunk = text_content[start..end],
            .result = ProcessResult{
                .keyword_matches = [_]usize{0} ** KEYWORDS.len,
                .total_matches = 0,
            },
        };

        threads[i] = try std.Thread.spawn(.{}, processTextChunk, .{&contexts[i]});
    }

    // Wait for all threads
    for (threads) |thread| {
        thread.join();
    }

    // Aggregate results
    var keyword_matches = [_]usize{0} ** KEYWORDS.len;
    var total_matches: usize = 0;

    for (contexts) |context| {
        for (context.result.keyword_matches, 0..) |count, j| {
            keyword_matches[j] += count;
        }
        total_matches += context.result.total_matches;
    }

    const end_time = std.time.nanoTimestamp();
    const elapsed_ms = @divFloor(end_time - start_time, 1_000_000);

    printResults(input_path, file_size, text_content.len, parse_time_ms, elapsed_ms, num_workers, keyword_matches, total_matches, text_content);
}

fn printResults(
    input_path: []const u8,
    file_size: u64,
    text_len: usize,
    parse_time_ms: i128,
    elapsed_ms: i128,
    num_workers: usize,
    keyword_matches: [KEYWORDS.len]usize,
    total_matches: usize,
    text_content: []const u8,
) void {
    std.debug.print("\n=== Zig Optimized HTML Keyword Filter ===\n", .{});
    std.debug.print("HTML file: {s}\n", .{input_path});
    std.debug.print("HTML size: {d} bytes\n", .{file_size});
    std.debug.print("Extracted text: {d} bytes\n", .{text_len});
    std.debug.print("HTML parsing time: {d}ms\n", .{parse_time_ms});
    std.debug.print("Total keywords: {d}\n", .{KEYWORDS.len});
    std.debug.print("Workers used: {d}\n", .{num_workers});
    std.debug.print("Total time: {d}ms\n", .{elapsed_ms});

    std.debug.print("\n--- Keyword Matches ---\n", .{});
    var found_count: usize = 0;

    for (KEYWORDS, 0..) |keyword, i| {
        if (keyword_matches[i] > 0) {
            std.debug.print("  {s}: {d} matches\n", .{ keyword, keyword_matches[i] });
            found_count += 1;
        }
    }

    std.debug.print("\n--- Summary ---\n", .{});
    std.debug.print("Unique keywords found: {d}/{d}\n", .{ found_count, KEYWORDS.len });
    std.debug.print("Total keyword occurrences: {d}\n", .{total_matches});

    const sample_len = @min(200, text_content.len);
    std.debug.print("\n--- Text Sample (first {d} chars) ---\n", .{sample_len});
    std.debug.print("{s}\n", .{text_content[0..sample_len]});

    if (total_matches > 0) {
        std.debug.print("\n✓ Content filtering detected {d} keyword matches\n", .{total_matches});
    } else {
        std.debug.print("\n✓ No keywords found - content appears clean\n", .{});
    }

    // Performance metrics
    if (elapsed_ms > 0) {
        const html_mb = @as(f64, @floatFromInt(file_size)) / (1024.0 * 1024.0);
        const throughput = html_mb / (@as(f64, @floatFromInt(elapsed_ms)) / 1000.0);
        std.debug.print("\nPerformance: {d:.2} MB/s\n", .{throughput});
    }
}
