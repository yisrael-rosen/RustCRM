const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const time = std.time;

// ============================================================================
// Multi-Layer Content Classifier - EXTENDED VERSION
// ============================================================================
// Layer 1: Fast keyword screening with 100-200 keywords
// Layer 2: Scoring and classification
// Layer 3: LLM routing decision
//
// Goal: Better coverage → Higher accuracy → 85%+ LLM reduction
// ============================================================================

// קטגוריה 1: מילות מפתח עסקיות/CRM (100 מילים)
const BUSINESS_KEYWORDS = [_][]const u8{
    // תקשורת ומידע (15 מילים)
    "שלום", "הודעה", "מידע", "עדכון", "התראה", "דיווח", "פרטים", "תיאור", "הסבר", "תוכן",
    "נתונים", "מסמך", "קובץ", "טופס", "דוח",

    // פעולות עסקיות (15 מילים)
    "רכישה", "מכירה", "עסקה", "הזמנה", "תשלום", "חשבונית", "הצעה", "חוזה", "הסכם", "דיל",
    "משא ומתן", "מו״מ", "עסק", "קניה", "מסחר",

    // סטטוס ומצב (15 מילים)
    "מאושר", "ממתין", "בטיפול", "הושלם", "בוטל", "נדחה", "פעיל", "סגור", "פתוח", "חדש",
    "בבדיקה", "טיוטה", "אושר", "בתהליך", "בהמתנה",

    // לקוחות וקשרים (15 מילים)
    "לקוח", "חברה", "איש קשר", "ספק", "שותף", "צוות", "מנהל", "משתמש", "משקיע", "יועץ",
    "קונה", "רוכש", "נציג", "סוכן", "לקוחה",

    // משימות ופעילות (15 מילים)
    "משימה", "פגישה", "שיחה", "אימייל", "פעילות", "מעקב", "תזכורת", "יומן", "לוח", "תכנון",
    "אירוע", "פגש", "ישיבה", "פרויקט", "תהליך",

    // CRM ו-Sales (15 מילים)
    "ליד", "לידים", "הזדמנות", "pipeline", "משפך", "המרה", "סגירה", "גיוס", "שימור", "נאמנות",
    "אפורטוניטי", "מכירות", "מוכר", "מכר", "מכירה",

    // פיננסים ותקציב (10 מילים)
    "הכנסה", "רווח", "הוצאה", "תקציב", "עלות", "מחיר", "שווי", "סכום", "כסף", "תשלום",

    // שיווק ומיתוג (10 מילים)
    "קמפיין", "פרסום", "מותג", "ברנדינג", "שיווק", "קידום", "מוצר", "שירות", "ערך", "יתרון",

    // טכנולוגיה ומערכות (10 מילים)
    "מערכת", "פלטפורמה", "אפליקציה", "תוכנה", "כלי", "ממשק", "אינטגרציה", "API", "נתוני", "בסיס נתונים",
};

// קטגוריה 2: מילות מפתח לתוכן רגיש (65 מילים)
const SENSITIVE_KEYWORDS = [_][]const u8{
    // מיניות ופורנוגרפיה (20 מילים)
    "סקס", "זין", "כוס", "מין", "ארוטי", "פורנו", "מבוגרים", "עירום", "מיני", "זונה",
    "זונות", "מאונן", "אוננות", "אורגזמה", "הומו", "לסביות", "xxx", "חשפנות", "סקסי", "מיניים",

    // הימורים וקזינו (12 מילים)
    "קזינו", "הימורים", "הגרלה", "מזל", "שחור", "בינגו", "פוקר", "בלקג'ק", "רולטה", "סלוטים",
    "הימור", "הימרן",

    // סמים ותרופות בלתי חוקיות (15 מילים)
    "סמים", "קוקאין", "הרואין", "קנאביס", "סם", "מריחואנה", "חשיש", "אקסטזי", "קוקה",
    "נרקוטי", "מסמם", "סמוך", "דילר", "משרף", "גראס",

    // תרופות מפוקפקות (5 מילים)
    "תרופות", "ויאגרה", "סיאליס", "כדורים", "תרופה",

    // אלימות וטרור (15 מילים)
    "אלימות", "נשק", "אקדח", "רובה", "פצצה", "טרור", "סכין", "חרב", "רימון", "מטען",
    "פיגוע", "טרוריסט", "דאעש", "פיצוץ", "פצוע",

    // גזענות ושנאה (10 מילים)
    "גזענות", "שנאה", "אפליה", "נאצי", "נאצים", "פשיזם", "קיצוני", "קיצונות", "קנאות", "שנאת",

    // קללות ובזיונות (8 מילים)
    "בזיון", "קללה", "גרוע", "חרא", "זבל", "מזדיין", "לעזאזל", "קללות",

    // תרמית והונאה (5 מילים)
    "הונאה", "תרמית", "פירמידה", "רמאות", "מלטי",

    // פיראטיות ופריצה (5 מילים)
    "פריצה", "האקינג", "קרקינג", "פיראטי", "פירוץ",
};

// HTML Parser (inline for simplicity)
const HtmlParser = struct {
    allocator: mem.Allocator,

    pub fn init(allocator: mem.Allocator) HtmlParser {
        return .{ .allocator = allocator };
    }

    pub fn extractText(self: *const HtmlParser, html: []const u8) ![]u8 {
        var result = std.ArrayList(u8).init(self.allocator);
        defer result.deinit();

        var in_tag = false;
        var in_script = false;
        var in_style = false;
        var i: usize = 0;

        while (i < html.len) {
            // Check for script tag
            if (i + 7 < html.len and mem.eql(u8, html[i .. i + 7], "<script")) {
                in_script = true;
                in_tag = true;
            }
            // Check for style tag
            if (i + 6 < html.len and mem.eql(u8, html[i .. i + 6], "<style")) {
                in_style = true;
                in_tag = true;
            }
            // Check for closing script
            if (i + 9 < html.len and mem.eql(u8, html[i .. i + 9], "</script>")) {
                in_script = false;
                in_tag = false;
                i += 9;
                continue;
            }
            // Check for closing style
            if (i + 8 < html.len and mem.eql(u8, html[i .. i + 8], "</style>")) {
                in_style = false;
                in_tag = false;
                i += 8;
                continue;
            }

            // Handle tag state
            if (html[i] == '<') {
                in_tag = true;
            } else if (html[i] == '>') {
                in_tag = false;
                i += 1;
                continue;
            }

            // Skip content inside tags, scripts, or styles
            if (in_tag or in_script or in_style) {
                i += 1;
                continue;
            }

            // Add text content
            try result.append(html[i]);
            i += 1;
        }

        return result.toOwnedSlice();
    }
};

// Classification result
const ContentClass = enum {
    CLEAN, // 0-5 matches total, safe to skip LLM
    BUSINESS_CONTENT, // High business score, likely CRM/business page
    SENSITIVE_CONTENT, // Contains sensitive keywords, needs review
    MIXED_CONTENT, // Both business and sensitive, needs LLM
    NEEDS_REVIEW, // Uncertain, send to LLM
};

const ClassificationResult = struct {
    content_class: ContentClass,
    business_score: usize,
    sensitive_score: usize,
    total_matches: usize,
    needs_llm: bool,
    confidence: f32,
    reason: []const u8,
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

fn classifyContent(business_score: usize, sensitive_score: usize) ClassificationResult {
    const total = business_score + sensitive_score;

    // Decision tree for LLM routing
    if (total <= 5) {
        // Very clean content - skip LLM
        return .{
            .content_class = .CLEAN,
            .business_score = business_score,
            .sensitive_score = sensitive_score,
            .total_matches = total,
            .needs_llm = false,
            .confidence = 0.95,
            .reason = "Low keyword density - likely clean content",
        };
    }

    if (sensitive_score == 0 and business_score >= 30) {
        // Clear business content - skip LLM (threshold raised for more keywords)
        return .{
            .content_class = .BUSINESS_CONTENT,
            .business_score = business_score,
            .sensitive_score = sensitive_score,
            .total_matches = total,
            .needs_llm = false,
            .confidence = 0.92,
            .reason = "High business keywords, no sensitive content",
        };
    }

    // NEW: High business content with very few sensitive words = likely false positives
    if (business_score >= 80 and sensitive_score <= 2) {
        // Heavily business-oriented with minimal sensitive content - skip LLM
        return .{
            .content_class = .BUSINESS_CONTENT,
            .business_score = business_score,
            .sensitive_score = sensitive_score,
            .total_matches = total,
            .needs_llm = false,
            .confidence = 0.88,
            .reason = "Dominant business content, minimal sensitive keywords (likely false positives)",
        };
    }

    // Moderate business with low sensitive ratio
    if (business_score >= 50 and sensitive_score > 0) {
        const sensitive_ratio = @as(f32, @floatFromInt(sensitive_score)) / @as(f32, @floatFromInt(business_score));
        if (sensitive_ratio < 0.05) {
            // Less than 5% sensitive keywords - probably clean business content
            return .{
                .content_class = .BUSINESS_CONTENT,
                .business_score = business_score,
                .sensitive_score = sensitive_score,
                .total_matches = total,
                .needs_llm = false,
                .confidence = 0.85,
                .reason = "Business content with low sensitive ratio (<5%)",
            };
        }
    }

    if (sensitive_score >= 5) {
        // Multiple sensitive keywords - needs review
        return .{
            .content_class = .SENSITIVE_CONTENT,
            .business_score = business_score,
            .sensitive_score = sensitive_score,
            .total_matches = total,
            .needs_llm = true,
            .confidence = 0.90,
            .reason = "Multiple sensitive keywords - requires deep analysis",
        };
    }

    if (sensitive_score >= 2 and sensitive_score <= 4) {
        // 2-4 sensitive keywords - likely needs review
        return .{
            .content_class = .SENSITIVE_CONTENT,
            .business_score = business_score,
            .sensitive_score = sensitive_score,
            .total_matches = total,
            .needs_llm = true,
            .confidence = 0.85,
            .reason = "Contains sensitive keywords - requires analysis",
        };
    }

    if (sensitive_score > 0 and business_score > 20) {
        // Mixed signals - send to LLM
        return .{
            .content_class = .MIXED_CONTENT,
            .business_score = business_score,
            .sensitive_score = sensitive_score,
            .total_matches = total,
            .needs_llm = true,
            .confidence = 0.70,
            .reason = "Mixed business and sensitive content",
        };
    }

    if (sensitive_score == 1) {
        // Single sensitive word - might be false positive
        return .{
            .content_class = .NEEDS_REVIEW,
            .business_score = business_score,
            .sensitive_score = sensitive_score,
            .total_matches = total,
            .needs_llm = true,
            .confidence = 0.65,
            .reason = "Unclear context - single sensitive keyword",
        };
    }

    // Default: moderate business content, skip LLM
    return .{
        .content_class = .BUSINESS_CONTENT,
        .business_score = business_score,
        .sensitive_score = sensitive_score,
        .total_matches = total,
        .needs_llm = false,
        .confidence = 0.75,
        .reason = "Moderate business content",
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: {s} <html_file>\n", .{args[0]});
        std.debug.print("\nMulti-Layer Content Classifier - EXTENDED VERSION\n", .{});
        std.debug.print("Features:\n", .{});
        std.debug.print("  • 100 business keywords (expanded coverage)\n", .{});
        std.debug.print("  • 65 sensitive keywords (comprehensive detection)\n", .{});
        std.debug.print("  • Total: 165 keywords for maximum accuracy\n", .{});
        std.debug.print("\nGoal: Reduce LLM calls by 85%+ with better coverage\n\n", .{});
        return;
    }

    const html_file = args[1];

    // Print header
    std.debug.print("\n=== Multi-Layer HTML Content Classifier [EXTENDED] ===\n", .{});
    std.debug.print("HTML file: {s}\n", .{html_file});
    std.debug.print("Keywords: {} business + {} sensitive = {} total\n", .{
        BUSINESS_KEYWORDS.len,
        SENSITIVE_KEYWORDS.len,
        BUSINESS_KEYWORDS.len + SENSITIVE_KEYWORDS.len,
    });

    // Read HTML file
    const start_time = time.milliTimestamp();
    const html_content = try fs.cwd().readFileAlloc(allocator, html_file, 10 * 1024 * 1024);
    defer allocator.free(html_content);

    const html_size = html_content.len;
    std.debug.print("HTML size: {} bytes\n", .{html_size});

    // Extract text from HTML
    const parser = HtmlParser.init(allocator);
    const text_content = try parser.extractText(html_content);
    defer allocator.free(text_content);

    std.debug.print("Extracted text: {} bytes\n", .{text_content.len});
    std.debug.print("Compression ratio: {d:.1}% (HTML overhead: {d:.1}%)\n", .{
        @as(f64, @floatFromInt(text_content.len)) / @as(f64, @floatFromInt(html_size)) * 100.0,
        (1.0 - @as(f64, @floatFromInt(text_content.len)) / @as(f64, @floatFromInt(html_size))) * 100.0,
    });

    // Layer 1: Fast keyword screening
    const layer1_start = time.milliTimestamp();

    var business_score: usize = 0;
    var sensitive_score: usize = 0;
    var business_matches: [BUSINESS_KEYWORDS.len]usize = [_]usize{0} ** BUSINESS_KEYWORDS.len;
    var sensitive_matches: [SENSITIVE_KEYWORDS.len]usize = [_]usize{0} ** SENSITIVE_KEYWORDS.len;

    // Scan business keywords
    for (BUSINESS_KEYWORDS, 0..) |keyword, i| {
        const count = countOccurrences(text_content, keyword);
        business_matches[i] = count;
        business_score += count;
    }

    // Scan sensitive keywords
    for (SENSITIVE_KEYWORDS, 0..) |keyword, i| {
        const count = countOccurrences(text_content, keyword);
        sensitive_matches[i] = count;
        sensitive_score += count;
    }

    const layer1_time = time.milliTimestamp() - layer1_start;

    // Layer 2: Content classification
    const result = classifyContent(business_score, sensitive_score);

    const total_time = time.milliTimestamp() - start_time;

    // Print results
    std.debug.print("\n--- Layer 1: Keyword Screening ({d}ms) ---\n", .{layer1_time});
    std.debug.print("Business keywords: {} total keywords, {} matches\n", .{ BUSINESS_KEYWORDS.len, business_score });
    std.debug.print("Sensitive keywords: {} total keywords, {} matches\n", .{ SENSITIVE_KEYWORDS.len, sensitive_score });

    // Show top business matches
    if (business_score > 0) {
        std.debug.print("\nTop business keywords:\n", .{});
        var shown: usize = 0;
        for (BUSINESS_KEYWORDS, 0..) |keyword, i| {
            if (business_matches[i] > 0 and shown < 10) {
                std.debug.print("  {s}: {} matches\n", .{ keyword, business_matches[i] });
                shown += 1;
            }
        }
    }

    // Show sensitive matches (if any)
    if (sensitive_score > 0) {
        std.debug.print("\n⚠️  Sensitive keywords found:\n", .{});
        var shown: usize = 0;
        for (SENSITIVE_KEYWORDS, 0..) |keyword, i| {
            if (sensitive_matches[i] > 0) {
                std.debug.print("  {s}: {} matches\n", .{ keyword, sensitive_matches[i] });
                shown += 1;
                if (shown >= 15) {
                    const remaining = sensitive_score - shown;
                    if (remaining > 0) {
                        std.debug.print("  ... and {} more\n", .{remaining});
                    }
                    break;
                }
            }
        }
    }

    // Print classification
    std.debug.print("\n--- Layer 2: Classification ---\n", .{});
    std.debug.print("Content Class: ", .{});
    switch (result.content_class) {
        .CLEAN => std.debug.print("✅ CLEAN\n", .{}),
        .BUSINESS_CONTENT => std.debug.print("📊 BUSINESS_CONTENT\n", .{}),
        .SENSITIVE_CONTENT => std.debug.print("🚫 SENSITIVE_CONTENT\n", .{}),
        .MIXED_CONTENT => std.debug.print("⚠️  MIXED_CONTENT\n", .{}),
        .NEEDS_REVIEW => std.debug.print("❓ NEEDS_REVIEW\n", .{}),
    }

    std.debug.print("Business Score: {}\n", .{result.business_score});
    std.debug.print("Sensitive Score: {}\n", .{result.sensitive_score});
    std.debug.print("Confidence: {d:.0}%\n", .{result.confidence * 100.0});
    std.debug.print("Reason: {s}\n", .{result.reason});

    // Layer 3: LLM routing decision
    std.debug.print("\n--- Layer 3: LLM Routing Decision ---\n", .{});
    if (result.needs_llm) {
        std.debug.print("🔴 SEND TO LLM for deep analysis\n", .{});
        std.debug.print("   Reason: {s}\n", .{result.reason});
    } else {
        std.debug.print("🟢 SKIP LLM - Content classified with high confidence\n", .{});
        std.debug.print("   ✅ Saved ~150ms LLM call time\n", .{});
    }

    // Performance summary
    std.debug.print("\n--- Performance Summary ---\n", .{});
    std.debug.print("Layer 1 (keyword scan): {}ms\n", .{layer1_time});
    std.debug.print("Total classification time: {}ms\n", .{total_time});
    if (text_content.len > 0 and layer1_time > 0) {
        const throughput = @as(f64, @floatFromInt(text_content.len)) / @as(f64, @floatFromInt(layer1_time)) * 1000.0 / (1024.0 * 1024.0);
        std.debug.print("Layer 1 throughput: {d:.2} MB/s\n", .{throughput});
    }
    std.debug.print("Keywords per ms: {d:.1}\n", .{
        @as(f64, @floatFromInt(BUSINESS_KEYWORDS.len + SENSITIVE_KEYWORDS.len)) / @as(f64, @floatFromInt(@max(layer1_time, 1))),
    });

    // Sample text
    std.debug.print("\n--- Text Sample ---\n", .{});
    const sample_len = @min(200, text_content.len);
    std.debug.print("{s}...\n", .{text_content[0..sample_len]});

    std.debug.print("\n", .{});
}
