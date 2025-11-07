const std = @import("std");
const HtmlParser = @import("html_parser.zig").HtmlParser;

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
        std.debug.print("Usage: {s} <input_file.html>\n", .{args[0]});
        std.debug.print("Filters HTML file for {d} Hebrew keywords\n", .{KEYWORDS.len});
        return error.InvalidArgs;
    }

    const input_path = args[1];

    // Start timing
    const start_time = std.time.nanoTimestamp();

    // Open and read HTML file
    const file = try std.fs.cwd().openFile(input_path, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const html_content = try file.readToEndAlloc(allocator, file_size);
    defer allocator.free(html_content);

    // Parse HTML and extract text
    const parser = HtmlParser.init(allocator);
    const text_content = try parser.extractText(html_content);
    defer allocator.free(text_content);

    // Search for keywords in extracted text
    var keyword_matches = [_]usize{0} ** KEYWORDS.len;
    var total_matches: usize = 0;

    for (KEYWORDS, 0..) |keyword, i| {
        var search_start: usize = 0;
        var count: usize = 0;

        // Count all occurrences of keyword
        while (search_start < text_content.len) {
            if (std.mem.indexOf(u8, text_content[search_start..], keyword)) |pos| {
                count += 1;
                search_start += pos + keyword.len;
            } else {
                break;
            }
        }

        keyword_matches[i] = count;
        total_matches += count;
    }

    // End timing
    const end_time = std.time.nanoTimestamp();
    const elapsed_ms = @divFloor(end_time - start_time, 1_000_000);

    // Print results
    std.debug.print("\n=== Zig HTML Keyword Filter ===\n", .{});
    std.debug.print("HTML file: {s}\n", .{input_path});
    std.debug.print("HTML size: {d} bytes\n", .{file_size});
    std.debug.print("Extracted text: {d} bytes\n", .{text_content.len});
    std.debug.print("Total keywords: {d}\n", .{KEYWORDS.len});
    std.debug.print("Time elapsed: {d}ms\n", .{elapsed_ms});

    // Print keyword statistics
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

    // Show sample of extracted text (first 200 chars)
    const sample_len = @min(200, text_content.len);
    std.debug.print("\n--- Text Sample (first {d} chars) ---\n", .{sample_len});
    std.debug.print("{s}\n", .{text_content[0..sample_len]});

    if (total_matches > 0) {
        std.debug.print("\n✓ Content filtering detected {d} keyword matches\n", .{total_matches});
    } else {
        std.debug.print("\n✓ No keywords found - content appears clean\n", .{});
    }
}
