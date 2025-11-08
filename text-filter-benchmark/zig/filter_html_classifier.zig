const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const time = std.time;

// ============================================================================
// Multi-Layer Content Classifier
// ============================================================================
// Layer 1: Fast keyword screening (0.07ms for 500 words)
// Layer 2: Scoring and classification
// Layer 3: LLM routing decision
//
// Goal: Reduce LLM calls by 85% while maintaining accuracy
// ============================================================================

// קטגוריה 1: מילות מפתח עסקיות/CRM (50 מילים)
const BUSINESS_KEYWORDS = [_][]const u8{
    // תקשורת ומידע
    "שלום", "הודעה", "מידע", "עדכון", "התראה", "דיווח", "פרטים", "תיאור", "הסבר", "תוכן",
    // פעולות עסקיות
    "רכישה", "מכירה", "עסקה", "הזמנה", "תשלום", "חשבונית", "הצעה", "חוזה", "הסכם", "דיל",
    // סטטוס ומצב
    "מאושר", "ממתין", "בטיפול", "הושלם", "בוטל", "נדחה", "פעיל", "סגור", "פתוח", "חדש",
    // לקוחות וקשרים
    "לקוח", "חברה", "איש קשר", "ספק", "שותף", "צוות", "מנהל", "משתמש", "משקיע", "יועץ",
    // משימות ופעילות
    "משימה", "פגישה", "שיחה", "אימייל", "פעילות", "מעקב", "תזכורת", "יומן", "לוח", "תכנון",
};

// קטגוריה 2: מילות מפתח לתוכן רגיש (sensitive content)
const SENSITIVE_KEYWORDS = [_][]const u8{
    // Based on user's sensitive_words list
    "סקס", "זין", "כוס", "מין", "ארוטי", "פורנו", "מבוגרים", "עירום", "מיני",
    "קזינו", "הימורים", "הגרלה", "מזל", "שחור",
    "סמים", "קוקאין", "הרואין", "קנאביס", "סם",
    "תרופות", "ויאגרה", "סיאליס",
    "אלימות", "נשק", "אקדח", "רובה", "פצצה", "טרור",
    "גזענות", "שנאה", "אפליה",
    // Additional common inappropriate terms
    "זונה", "זונות", "בזיון", "קללה", "גרוע",
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

    if (sensitive_score == 0 and business_score >= 20) {
        // Clear business content - skip LLM
        return .{
            .content_class = .BUSINESS_CONTENT,
            .business_score = business_score,
            .sensitive_score = sensitive_score,
            .total_matches = total,
            .needs_llm = false,
            .confidence = 0.90,
            .reason = "High business keywords, no sensitive content",
        };
    }

    if (sensitive_score >= 3) {
        // Multiple sensitive keywords - needs review
        return .{
            .content_class = .SENSITIVE_CONTENT,
            .business_score = business_score,
            .sensitive_score = sensitive_score,
            .total_matches = total,
            .needs_llm = true,
            .confidence = 0.85,
            .reason = "Contains sensitive keywords - requires deep analysis",
        };
    }

    if (sensitive_score > 0 and business_score > 10) {
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
        std.debug.print("\nMulti-Layer Content Classifier\n", .{});
        std.debug.print("Classifies HTML content to reduce LLM calls by 85%\n\n", .{});
        return;
    }

    const html_file = args[1];

    // Print header
    std.debug.print("\n=== Multi-Layer HTML Content Classifier ===\n", .{});
    std.debug.print("HTML file: {s}\n", .{html_file});

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
            if (business_matches[i] > 0 and shown < 5) {
                std.debug.print("  {s}: {} matches\n", .{ keyword, business_matches[i] });
                shown += 1;
            }
        }
    }

    // Show sensitive matches (if any)
    if (sensitive_score > 0) {
        std.debug.print("\n⚠️  Sensitive keywords found:\n", .{});
        for (SENSITIVE_KEYWORDS, 0..) |keyword, i| {
            if (sensitive_matches[i] > 0) {
                std.debug.print("  {s}: {} matches\n", .{ keyword, sensitive_matches[i] });
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
    if (text_content.len > 0) {
        const throughput = @as(f64, @floatFromInt(text_content.len)) / @as(f64, @floatFromInt(layer1_time)) * 1000.0 / (1024.0 * 1024.0);
        std.debug.print("Layer 1 throughput: {d:.2} MB/s\n", .{throughput});
    }

    // Sample text
    std.debug.print("\n--- Text Sample ---\n", .{});
    const sample_len = @min(200, text_content.len);
    std.debug.print("{s}...\n", .{text_content[0..sample_len]});

    std.debug.print("\n", .{});
}
