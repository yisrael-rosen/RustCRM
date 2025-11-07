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

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: {s} <input_file>\n", .{args[0]});
        std.debug.print("Searches for {d} Hebrew keywords in the file\n", .{KEYWORDS.len});
        return error.InvalidArgs;
    }

    const input_path = args[1];

    // Start timing
    const start_time = std.time.nanoTimestamp();

    // Open input file
    const file = try std.fs.cwd().openFile(input_path, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const content = try file.readToEndAlloc(allocator, file_size);
    defer allocator.free(content);

    // Create hash map for keyword lookup
    var keyword_map = std.StringHashMap(void).init(allocator);
    defer keyword_map.deinit();

    for (KEYWORDS) |keyword| {
        try keyword_map.put(keyword, {});
    }

    // Filter lines
    var line_iter = std.mem.splitSequence(u8, content, "\n");
    var match_count: usize = 0;
    var total_lines: usize = 0;
    var output_size: usize = 0;
    var keyword_matches = std.StringHashMap(usize).init(allocator);
    defer keyword_matches.deinit();

    while (line_iter.next()) |line| {
        total_lines += 1;
        var line_has_match = false;

        // Check each keyword
        for (KEYWORDS) |keyword| {
            if (std.mem.indexOf(u8, line, keyword) != null) {
                if (!line_has_match) {
                    match_count += 1;
                    output_size += line.len + 1;
                    line_has_match = true;
                }

                // Count keyword occurrences
                const entry = try keyword_matches.getOrPut(keyword);
                if (!entry.found_existing) {
                    entry.value_ptr.* = 0;
                }
                entry.value_ptr.* += 1;
            }
        }
    }

    // End timing
    const end_time = std.time.nanoTimestamp();
    const elapsed_ms = @divFloor(end_time - start_time, 1_000_000);

    // Print results
    std.debug.print("\n=== Zig Multi-Keyword Text Filter ===\n", .{});
    std.debug.print("Total keywords: {d}\n", .{KEYWORDS.len});
    std.debug.print("Total lines: {d}\n", .{total_lines});
    std.debug.print("Matching lines: {d}\n", .{match_count});
    std.debug.print("Time elapsed: {d}ms\n", .{elapsed_ms});
    std.debug.print("Output size: {d} bytes\n", .{output_size});

    // Print keyword statistics
    std.debug.print("\n--- Keyword Matches ---\n", .{});
    var iter = keyword_matches.iterator();
    var found_count: usize = 0;
    while (iter.next()) |entry| {
        std.debug.print("  {s}: {d} matches\n", .{entry.key_ptr.*, entry.value_ptr.*});
        found_count += 1;
    }
    std.debug.print("Total unique keywords found: {d}/{d}\n", .{found_count, KEYWORDS.len});
}
