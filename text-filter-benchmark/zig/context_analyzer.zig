const std = @import("std");
const mem = std.mem;

// ============================================================================
// Context-Aware Keyword Analyzer
// ============================================================================
// Simple but effective algorithms for context analysis and keyword weighting
// Goal: Reduce false positives and improve classification accuracy
// ============================================================================

/// Keyword with weight (1.0 = neutral, >1.0 = strong signal, <1.0 = weak)
pub const WeightedKeyword = struct {
    word: []const u8,
    weight: f32,
    category: KeywordCategory,
};

pub const KeywordCategory = enum {
    HIGHLY_AMBIGUOUS, // מילים דו-משמעיות (מין, זין, סם)
    AMBIGUOUS, // מעט דו-משמעיות
    CLEAR, // חד-משמעיות
    VERY_CLEAR, // ממש חד-משמעיות (פורנו, קזינו)
};

// ============================================================================
// Algorithm 1: Weighted Keywords
// ============================================================================
// Simple: Give different weights to different keywords
// Reduces impact of ambiguous words like "מין" (species vs sex)
// ============================================================================

pub const WeightedSensitiveKeywords = [_]WeightedKeyword{
    // VERY_CLEAR: No ambiguity (weight 10.0)
    .{ .word = "פורנו", .weight = 10.0, .category = .VERY_CLEAR },
    .{ .word = "xxx", .weight = 10.0, .category = .VERY_CLEAR },
    .{ .word = "קזינו", .weight = 10.0, .category = .VERY_CLEAR },
    .{ .word = "קוקאין", .weight = 10.0, .category = .VERY_CLEAR },
    .{ .word = "הרואין", .weight = 10.0, .category = .VERY_CLEAR },

    // CLEAR: Little ambiguity (weight 5.0)
    .{ .word = "סקס", .weight = 5.0, .category = .CLEAR },
    .{ .word = "הימורים", .weight = 5.0, .category = .CLEAR },
    .{ .word = "ארוטי", .weight = 5.0, .category = .CLEAR },
    .{ .word = "אלימות", .weight = 5.0, .category = .CLEAR },

    // AMBIGUOUS: Context matters (weight 1.0)
    .{ .word = "מבוגרים", .weight = 1.0, .category = .AMBIGUOUS }, // adults or content?
    .{ .word = "עירום", .weight = 1.0, .category = .AMBIGUOUS }, // art or porn?
    .{ .word = "תרופות", .weight = 1.0, .category = .AMBIGUOUS }, // medicine or drugs?

    // HIGHLY_AMBIGUOUS: Very context dependent (weight 0.3)
    .{ .word = "מין", .weight = 0.3, .category = .HIGHLY_AMBIGUOUS }, // species vs sex
    .{ .word = "זין", .weight = 0.3, .category = .HIGHLY_AMBIGUOUS }, // zine vs profanity
    .{ .word = "סם", .weight = 0.3, .category = .HIGHLY_AMBIGUOUS }, // symbol vs drug
    .{ .word = "מיני", .weight = 0.3, .category = .HIGHLY_AMBIGUOUS }, // mini vs sexual
    .{ .word = "שחור", .weight = 0.3, .category = .HIGHLY_AMBIGUOUS }, // black vs gambling
};

/// Calculate weighted score instead of simple count
pub fn calculateWeightedScore(text: []const u8) f32 {
    var score: f32 = 0.0;

    for (WeightedSensitiveKeywords) |kw| {
        const count = countOccurrences(text, kw.word);
        score += @as(f32, @floatFromInt(count)) * kw.weight;
    }

    return score;
}

// ============================================================================
// Algorithm 2: Context Window Analysis
// ============================================================================
// Check words before/after the keyword to understand context
// Example: "מין" + "בעלי חיים" = scientific, "מין" + "סקס" = sexual
// ============================================================================

/// Context indicators: words that appear near sensitive keywords
pub const ContextIndicators = struct {
    // If these words appear near sensitive keyword → probably innocent
    pub const INNOCENT_CONTEXT = [_][]const u8{
        // Science/Biology
        "מדע", "מדעי", "מחקר", "ביולוגיה", "בעלי חיים", "צמחים", "אבולוציה",
        "מינים", "סוגים", "קטגוריה",

        // Business/Official
        "חוק", "חוקי", "רשמי", "ממשלה", "משרד", "תקנון", "מדיניות",

        // Medicine
        "רפואה", "רפואי", "רופא", "בית חולים", "טיפול", "מרשם",

        // Education
        "חינוך", "חינוכי", "בית ספר", "אוניברסיטה", "לימוד", "מורה",

        // Art/Culture
        "אמנות", "אמנותי", "פסל", "ציור", "תערוכה", "מוזיאון", "תרבות",
    };

    // If these words appear near sensitive keyword → probably sensitive
    pub const SENSITIVE_CONTEXT = [_][]const u8{
        // Adult content
        "סרט", "סרטים", "וידאו", "אתר", "אתרים", "צפייה", "הורדה",
        "בחינם", "free", "hot", "sexy",

        // Gambling
        "הימור", "הימרן", "משחק", "משחקים", "זכייה", "לזכות", "הגרלה",

        // Illegal
        "שוק שחור", "בלתי חוקי", "לא חוקי", "מכירה", "רכישה", "דילר",
    };
};

/// Analyze context window (N words before/after keyword)
pub fn analyzeContext(
    text: []const u8,
    keyword_pos: usize,
    window_size: usize,
) ContextScore {
    const start = if (keyword_pos > window_size * 20) keyword_pos - window_size * 20 else 0;
    const end = @min(keyword_pos + window_size * 20, text.len);
    const context_window = text[start..end];

    var innocent_count: usize = 0;
    var sensitive_count: usize = 0;

    // Count innocent indicators
    for (ContextIndicators.INNOCENT_CONTEXT) |indicator| {
        if (mem.indexOf(u8, context_window, indicator) != null) {
            innocent_count += 1;
        }
    }

    // Count sensitive indicators
    for (ContextIndicators.SENSITIVE_CONTEXT) |indicator| {
        if (mem.indexOf(u8, context_window, indicator) != null) {
            sensitive_count += 1;
        }
    }

    return .{
        .innocent_score = innocent_count,
        .sensitive_score = sensitive_count,
        .context_window = context_window,
    };
}

pub const ContextScore = struct {
    innocent_score: usize,
    sensitive_score: usize,
    context_window: []const u8,

    pub fn getMultiplier(self: *const ContextScore) f32 {
        if (self.innocent_score > self.sensitive_score) {
            // Innocent context → reduce weight by 50-90%
            const reduction = @min(0.9, @as(f32, @floatFromInt(self.innocent_score)) * 0.3);
            return 1.0 - reduction;
        } else if (self.sensitive_score > self.innocent_score) {
            // Sensitive context → increase weight by 50-200%
            const boost = @min(2.0, @as(f32, @floatFromInt(self.sensitive_score)) * 0.5);
            return 1.0 + boost;
        }
        return 1.0; // Neutral
    }
};

// ============================================================================
// Algorithm 3: Co-occurrence Patterns
// ============================================================================
// Check if certain keyword pairs appear together
// Example: "מין" + "מינים" = scientific terminology
// ============================================================================

pub const CooccurrencePattern = struct {
    keyword: []const u8,
    positive_pairs: []const []const u8, // If found together → boost innocent
    negative_pairs: []const []const u8, // If found together → boost sensitive
};

pub const COOCCURRENCE_PATTERNS = [_]CooccurrencePattern{
    .{
        .keyword = "מין",
        .positive_pairs = &[_][]const u8{ "מינים", "בעלי חיים", "סוגים", "ביולוגיה" },
        .negative_pairs = &[_][]const u8{ "סקס", "מיני", "ארוטי", "פורנו" },
    },
    .{
        .keyword = "מבוגרים",
        .positive_pairs = &[_][]const u8{ "חינוך", "לימוד", "קורס", "סדנה" },
        .negative_pairs = &[_][]const u8{ "תוכן", "סרטים", "אתר", "xxx" },
    },
    .{
        .keyword = "שחור",
        .positive_pairs = &[_][]const u8{ "צבע", "לבן", "אדום", "לבוש" },
        .negative_pairs = &[_][]const u8{ "שוק", "הימור", "קזינו", "בלתי חוקי" },
    },
};

pub fn checkCooccurrence(text: []const u8, keyword: []const u8) f32 {
    var multiplier: f32 = 1.0;

    for (COOCCURRENCE_PATTERNS) |pattern| {
        if (mem.eql(u8, pattern.keyword, keyword)) {
            // Check positive pairs
            for (pattern.positive_pairs) |pair| {
                if (mem.indexOf(u8, text, pair) != null) {
                    multiplier *= 0.5; // Reduce sensitivity
                }
            }

            // Check negative pairs
            for (pattern.negative_pairs) |pair| {
                if (mem.indexOf(u8, text, pair) != null) {
                    multiplier *= 2.0; // Increase sensitivity
                }
            }
        }
    }

    return multiplier;
}

// ============================================================================
// Algorithm 4: Proximity-based Scoring
// ============================================================================
// Keywords that appear close together are more significant
// Example: "סקס" and "פורנו" within 50 chars = strong signal
// ============================================================================

pub fn calculateProximityBoost(
    text: []const u8,
    keyword1: []const u8,
    keyword2: []const u8,
    max_distance: usize,
) f32 {
    var pos1: usize = 0;
    var boost: f32 = 0.0;

    while (pos1 < text.len) {
        if (mem.indexOf(u8, text[pos1..], keyword1)) |found1| {
            const actual_pos1 = pos1 + found1;

            // Look for keyword2 nearby
            const search_start = if (actual_pos1 > max_distance) actual_pos1 - max_distance else 0;
            const search_end = @min(actual_pos1 + max_distance, text.len);

            if (mem.indexOf(u8, text[search_start..search_end], keyword2) != null) {
                // Found both keywords close together
                boost += 1.5;
            }

            pos1 = actual_pos1 + keyword1.len;
        } else {
            break;
        }
    }

    return boost;
}

// ============================================================================
// Combined Context-Aware Scoring
// ============================================================================

pub const ContextAwareResult = struct {
    raw_score: f32,
    weighted_score: f32,
    context_adjusted_score: f32,
    final_score: f32,
    explanation: []const u8,
};

pub fn analyzeWithContext(text: []const u8) ContextAwareResult {
    // Step 1: Calculate weighted score
    const weighted = calculateWeightedScore(text);

    // Step 2: Apply context analysis for ambiguous words
    var context_adjusted = weighted;

    // Find all ambiguous keywords and analyze their context
    for (WeightedSensitiveKeywords) |kw| {
        if (kw.category == .HIGHLY_AMBIGUOUS or kw.category == .AMBIGUOUS) {
            var pos: usize = 0;
            while (pos < text.len) {
                if (mem.indexOf(u8, text[pos..], kw.word)) |found_pos| {
                    const actual_pos = pos + found_pos;

                    // Analyze context window
                    const context = analyzeContext(text, actual_pos, 10);
                    const context_mult = context.getMultiplier();

                    // Apply co-occurrence
                    const cooccur_mult = checkCooccurrence(text, kw.word);

                    // Adjust score
                    context_adjusted += kw.weight * context_mult * cooccur_mult - kw.weight;

                    pos = actual_pos + kw.word.len;
                } else {
                    break;
                }
            }
        }
    }

    // Step 3: Check proximity of high-signal keywords
    const proximity_boost = calculateProximityBoost(text, "סקס", "פורנו", 100) +
        calculateProximityBoost(text, "קזינו", "הימורים", 100);

    const final_score = context_adjusted + proximity_boost;

    return .{
        .raw_score = weighted,
        .weighted_score = weighted,
        .context_adjusted_score = context_adjusted,
        .final_score = final_score,
        .explanation = if (final_score < 2.0)
            "Low score - likely innocent"
        else if (final_score < 5.0)
            "Moderate score - needs review"
        else
            "High score - likely sensitive",
    };
}

// ============================================================================
// Helper Functions
// ============================================================================

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

// ============================================================================
// Test / Demo
// ============================================================================

pub fn main() !void {
    std.debug.print("\n=== Context-Aware Keyword Analyzer Demo ===\n\n", .{});

    // Test 1: Scientific context (innocent)
    const text1 = "המחקר בדק מינים שונים של בעלי חיים. יש מגוון רחב של מינים בטבע.";
    std.debug.print("Test 1: Scientific text\n", .{});
    std.debug.print("Text: {s}\n", .{text1});

    const result1 = analyzeWithContext(text1);
    std.debug.print("Raw score: {d:.2}\n", .{result1.raw_score});
    std.debug.print("Context-adjusted: {d:.2}\n", .{result1.context_adjusted_score});
    std.debug.print("Final score: {d:.2}\n", .{result1.final_score});
    std.debug.print("Explanation: {s}\n\n", .{result1.explanation});

    // Test 2: Adult content (sensitive)
    const text2 = "אתר למבוגרים עם תוכן מיני ופורנו. סרטי סקס בחינם.";
    std.debug.print("Test 2: Adult content\n", .{});
    std.debug.print("Text: {s}\n", .{text2});

    const result2 = analyzeWithContext(text2);
    std.debug.print("Raw score: {d:.2}\n", .{result2.raw_score});
    std.debug.print("Context-adjusted: {d:.2}\n", .{result2.context_adjusted_score});
    std.debug.print("Final score: {d:.2}\n", .{result2.final_score});
    std.debug.print("Explanation: {s}\n\n", .{result2.explanation});

    // Test 3: Medicine context (innocent)
    const text3 = "תרופות רפואיות מבית החולים. הרופא רשם מרשם לטיפול.";
    std.debug.print("Test 3: Medical text\n", .{});
    std.debug.print("Text: {s}\n", .{text3});

    const result3 = analyzeWithContext(text3);
    std.debug.print("Raw score: {d:.2}\n", .{result3.raw_score});
    std.debug.print("Context-adjusted: {d:.2}\n", .{result3.context_adjusted_score});
    std.debug.print("Final score: {d:.2}\n", .{result3.final_score});
    std.debug.print("Explanation: {s}\n\n", .{result3.explanation});

    // Show weighted keywords
    std.debug.print("=== Weighted Keywords ===\n", .{});
    for (WeightedSensitiveKeywords) |kw| {
        std.debug.print("  '{s}': weight={d:.1}, category={s}\n", .{
            kw.word,
            kw.weight,
            @tagName(kw.category),
        });
    }
}
