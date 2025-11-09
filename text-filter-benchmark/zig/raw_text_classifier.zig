const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const time = std.time;

// ============================================================================
// RAW TEXT CLASSIFIER - NO HTML PARSING
// ============================================================================
// Scans entire file content "blindly" including HTML tags, scripts, etc.
// Advantages: MUCH faster (no parsing overhead)
// Disadvantages: More false positives (matches in tags, JS, CSS)
// ============================================================================

const BUSINESS_KEYWORDS = [_][]const u8{
    // Core business (30 most important)
    "לקוח", "לקוחה", "לקוחות", "חברה", "עסק", "מכירה", "רכישה",
    "מידע", "נתונים", "דיווח", "עדכון", "הזמנה", "תשלום", "חשבונית",
    "מנהל", "ניהול", "צוות", "פגישה", "משימה", "פרויקט", "תכנון",
    "שיווק", "קמפיין", "פרסום", "מותג", "ברנדינג", "קידום",
    "ליד", "לידים", "pipeline", "המרה",

    // Extended business (90 more)
    "CRM", "ארגון", "הנהלה", "מנכל", "סמנכל", "עובד", "עובדים",
    "משתמש", "משתמשים", "נציג", "סוכן", "ספק", "שותף", "משקיע",
    "יועץ", "ייעוץ", "מחלקה", "אגף", "תפקיד", "אחריות",
    "הכנסה", "הכנסות", "רווח", "רווחיות", "הוצאה", "עלות",
    "תקציב", "מחיר", "תמחור", "סכום", "כסף", "שווי", "השקעה",
    "מימון", "אשראי", "מס", "חשבונאות", "קבלה",
    "מוצר", "מוצרים", "שירות", "שירותים", "ערך", "יתרון",
    "תחרות", "שוק", "מגזר", "ענף", "תעשייה", "מסחר",
    "מערכת", "פלטפורמה", "תוכנה", "אפליקציה", "ממשק",
    "אינטגרציה", "API", "דשבורד", "אוטומציה", "דיגיטלי",
    "סטטוס", "מאושר", "ממתין", "בטיפול", "הושלם", "פעיל",
    "אסטרטגיה", "יעד", "מטרה", "ביצועים", "מדידה", "ניתוח",
    "גיוס", "שימור", "נאמנות", "משוב", "דרישות", "ציפיות",
    "הצעה", "חוזה", "הסכם", "דיל", "עסקה", "קניה",
    "מסמך", "טופס", "קובץ", "דוח", "פרטים", "תוכן",
    "תקשורת", "הודעה", "התראה", "הנחיה", "הוראה",
};

const SENSITIVE_KEYWORDS = [_][]const u8{
    // Very clear sensitive (20 words, weight 10.0)
    "פורנו", "פורנוגרפיה", "xxx", "קזינו", "קזינאות",
    "קוקאין", "הרואין", "אקסטזי", "LSD", "MDMA",

    // Clear sensitive (30 words, weight 5.0)
    "סקס", "ארוטי", "ארוטיקה", "הימורים", "הימור", "הימרן",
    "זונה", "זונות", "זנות", "חשפנות", "מאונן", "אוננות",
    "קנאביס", "מריחואנה", "חשיש", "נרקוטי", "נרקוטים",
    "ויאגרה", "סיאליס", "פוקר", "בלקג'ק", "רולטה", "סלוטים",
    "חרא", "מזדיין", "לעזאזל", "בזיון", "תרמית", "רמאות",

    // Ambiguous (45 words, weight 0.3-1.0)
    "מין", "מיני", "מיניים", "מבוגרים", "עירום", "סמים", "סם",
    "זין", "כוס", "תרופות", "אלימות", "נשק", "טרור",
    "גזענות", "שנאה", "אפליה", "קללה", "הונאה", "גניבה",
    "פריצה", "האקינג", "פיראטי", "זבל", "גרוע", "שחור",
    "מזל", "הגרלה", "שוק שחור", "בלתי חוקי", "דילר",
    "פצצה", "רימון", "רובה", "אקדח", "סכין", "פיגוע",
    "רצח", "רוצח", "נאצי", "פשיזם", "קיצוני", "הסתה",
    "זיוף", "מזויף", "רמאי", "פונזי",
};

fn countOccurrences(text: []const u8, keyword: []const u8) usize {
    var count: usize = 0;
    var pos: usize = 0;

    while (pos < text.len) {
        if (mem.indexOf(u8, text[pos..], keyword)) |found_pos| {
            count += 1;
            pos += found_pos + keyword.len;
        } else {
            break;
        }
    }

    return count;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: {s} <file>\n", .{args[0]});
        std.debug.print("\nRAW TEXT CLASSIFIER (No HTML parsing)\n", .{});
        std.debug.print("Scans entire file blindly - FAST but less accurate\n\n", .{});
        return;
    }

    const file_path = args[1];

    std.debug.print("\n=== RAW TEXT CLASSIFIER (No HTML Parsing) ===\n", .{});
    std.debug.print("File: {s}\n", .{file_path});

    // Read entire file as-is (no parsing!)
    const start_time = time.milliTimestamp();
    const content = try fs.cwd().readFileAlloc(allocator, file_path, 10 * 1024 * 1024);
    defer allocator.free(content);

    const file_size = content.len;
    std.debug.print("File size: {} bytes\n", .{file_size});

    // Scan raw content
    const scan_start = time.milliTimestamp();

    var business_score: usize = 0;
    var sensitive_score: usize = 0;

    // Business keywords
    for (BUSINESS_KEYWORDS) |keyword| {
        const count = countOccurrences(content, keyword);
        business_score += count;
    }

    // Sensitive keywords
    for (SENSITIVE_KEYWORDS) |keyword| {
        const count = countOccurrences(content, keyword);
        sensitive_score += count;
    }

    const scan_time = time.milliTimestamp() - scan_start;
    const total_time = time.milliTimestamp() - start_time;

    // Classification (same logic as extended classifier)
    const total = business_score + sensitive_score;
    var decision: []const u8 = undefined;
    var class: []const u8 = undefined;

    if (total <= 5) {
        class = "CLEAN";
        decision = "SKIP LLM";
    } else if (sensitive_score == 0 and business_score >= 30) {
        class = "BUSINESS_CONTENT";
        decision = "SKIP LLM";
    } else if (business_score >= 80 and sensitive_score <= 2) {
        class = "BUSINESS_CONTENT";
        decision = "SKIP LLM";
    } else if (sensitive_score >= 5) {
        class = "SENSITIVE_CONTENT";
        decision = "SEND TO LLM";
    } else if (sensitive_score >= 2) {
        class = "SENSITIVE_CONTENT";
        decision = "SEND TO LLM";
    } else if (sensitive_score > 0 and business_score > 20) {
        class = "MIXED_CONTENT";
        decision = "SEND TO LLM";
    } else if (sensitive_score == 1) {
        class = "NEEDS_REVIEW";
        decision = "SEND TO LLM";
    } else {
        class = "BUSINESS_CONTENT";
        decision = "SKIP LLM";
    }

    // Print results
    std.debug.print("\n--- Scan Results ---\n", .{});
    std.debug.print("Business keywords: {} (from {} total)\n", .{ business_score, BUSINESS_KEYWORDS.len });
    std.debug.print("Sensitive keywords: {} (from {} total)\n", .{ sensitive_score, SENSITIVE_KEYWORDS.len });
    std.debug.print("Total matches: {}\n", .{total});

    std.debug.print("\n--- Classification ---\n", .{});
    std.debug.print("Class: {s}\n", .{class});
    std.debug.print("Decision: {s}\n", .{decision});

    std.debug.print("\n--- Performance ---\n", .{});
    std.debug.print("Scan time: {}ms\n", .{scan_time});
    std.debug.print("Total time: {}ms (including file read)\n", .{total_time});

    if (file_size > 0 and scan_time > 0) {
        const throughput = @as(f64, @floatFromInt(file_size)) / @as(f64, @floatFromInt(scan_time)) * 1000.0 / (1024.0 * 1024.0);
        std.debug.print("Throughput: {d:.2} MB/s\n", .{throughput});
    }

    const keywords_per_ms = @as(f64, @floatFromInt(BUSINESS_KEYWORDS.len + SENSITIVE_KEYWORDS.len)) / @as(f64, @floatFromInt(@max(scan_time, 1)));
    std.debug.print("Keywords/ms: {d:.1}\n", .{keywords_per_ms});

    std.debug.print("\n", .{});
}
