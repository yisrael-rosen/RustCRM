const std = @import("std");
const mem = std.mem;

// ============================================================================
// Hebrew Inflections Matcher
// ============================================================================
// Smart approach: Store 400 base words, match with prefixes in code
// Instead of storing 2,800 words (400 × 7 forms)
// ============================================================================

// Hebrew prefixes (תחיליות)
const HEBREW_PREFIXES = [_][]const u8{
    "ה", // ה' הידיעה
    "ב", // ב' מקום
    "ל", // ל' כיוון
    "מ", // מ' מקום
    "כ", // כ' דמיון
    "ש", // ש' קשר
    "ו", // ו' החיבור
};

// Common double prefixes (תחיליות כפולות)
const HEBREW_DOUBLE_PREFIXES = [_][]const u8{
    "וב",
    "וה",
    "ול",
    "ומ",
    "וכ",
    "וש",
    "שב",
    "של",
    "שמ",
    "מה",
    "בה",
    "כש",
};

/// Check if a word in text matches the base keyword (with or without prefixes)
/// Example: keyword "לקוח" matches "לקוח", "הלקוח", "בלקוח", "וללקוח", etc.
pub fn matchesWithInflections(text_word: []const u8, base_keyword: []const u8) bool {
    // Direct match
    if (mem.eql(u8, text_word, base_keyword)) {
        return true;
    }

    // Check if text_word ends with base_keyword (i.e., has a prefix)
    if (text_word.len <= base_keyword.len) {
        return false;
    }

    // Check single prefixes
    for (HEBREW_PREFIXES) |prefix| {
        if (text_word.len == prefix.len + base_keyword.len) {
            if (mem.startsWith(u8, text_word, prefix) and
                mem.endsWith(u8, text_word, base_keyword)) {
                return true;
            }
        }
    }

    // Check double prefixes (וה, של, etc.)
    for (HEBREW_DOUBLE_PREFIXES) |prefix| {
        if (text_word.len == prefix.len + base_keyword.len) {
            if (mem.startsWith(u8, text_word, prefix) and
                mem.endsWith(u8, text_word, base_keyword)) {
                return true;
            }
        }
    }

    return false;
}

/// Count occurrences of base keyword with all inflections
/// Much faster than searching for all 7 forms separately
pub fn countOccurrencesWithInflections(text: []const u8, base_keyword: []const u8) usize {
    var count: usize = 0;
    var pos: usize = 0;

    // Simple word-boundary search
    // In Hebrew, words are typically separated by spaces, punctuation, or HTML
    while (pos < text.len) {
        // Find next occurrence of the base keyword
        if (mem.indexOf(u8, text[pos..], base_keyword)) |found_pos| {
            const actual_pos = pos + found_pos;

            // Simple heuristic: if preceded by space/punctuation, it's a match
            // If preceded by Hebrew letter, check if it's a valid prefix
            if (actual_pos == 0) {
                // Start of text - count it
                count += 1;
            } else if (text[actual_pos - 1] == ' ' or
                       text[actual_pos - 1] == '\n' or
                       text[actual_pos - 1] == '.' or
                       text[actual_pos - 1] == ',' or
                       text[actual_pos - 1] == '"' or
                       text[actual_pos - 1] == '>' or
                       text[actual_pos - 1] == ')') {
                // Preceded by whitespace/punctuation - count it
                count += 1;
            } else {
                // Preceded by other characters - check for valid Hebrew prefix
                // This is a simplified version; full implementation would check UTF-8 boundaries
                const prefix_start = if (actual_pos >= 3) actual_pos - 3 else 0;
                const potential_prefix = text[prefix_start..actual_pos];

                var has_valid_prefix = false;
                for (HEBREW_PREFIXES) |prefix| {
                    if (mem.endsWith(u8, potential_prefix, prefix)) {
                        has_valid_prefix = true;
                        break;
                    }
                }

                if (has_valid_prefix) {
                    count += 1;
                }
            }

            pos = actual_pos + base_keyword.len;
        } else {
            break;
        }
    }

    return count;
}

// Test function
pub fn main() !void {
    // Example usage
    const test_text = "הלקוח רכש מוצר. לקוח נוסף הזמין שירות. בלקוח הזה יש בעיה.";
    const base_keyword = "לקוח";

    const count = countOccurrencesWithInflections(test_text, base_keyword);
    std.debug.print("Found '{s}' {} times (with inflections)\n", .{ base_keyword, count });

    // Test individual matches
    const words = [_][]const u8{ "לקוח", "הלקוח", "בלקוח", "ללקוח", "מלקוח", "כלקוח", "שלקוח", "וללקוח" };
    for (words) |word| {
        const matches = matchesWithInflections(word, base_keyword);
        std.debug.print("  '{s}' matches: {}\n", .{ word, matches });
    }
}
