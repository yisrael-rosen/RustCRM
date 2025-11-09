// WASM keyword detector - demonstrating how strings appear in WASM
const std = @import("std");

// Keywords embedded in WASM binary
const KEYWORDS = [_][]const u8{
    "פורנוגרפיה",              // Sensitive keyword
    "הימורים",                 // Gambling
    "קזינו",                   // Casino
    "16TXldem16DXldeS16jXpNeZ15Qg",  // Base64: "פורנוגרפיה"
    "15TXmdee15XXldeo15nXnQ==",      // Base64: "הימורים"
};

// Export function to detect keywords
export fn detectKeywords(text_ptr: [*]const u8, text_len: usize) i32 {
    const text = text_ptr[0..text_len];

    var count: i32 = 0;
    for (KEYWORDS) |keyword| {
        if (indexOf(text, keyword)) {
            count += 1;
        }
    }

    return count;
}

// Simple indexOf without std.mem (for smaller binary)
fn indexOf(haystack: []const u8, needle: []const u8) bool {
    if (needle.len > haystack.len) return false;

    var i: usize = 0;
    while (i <= haystack.len - needle.len) : (i += 1) {
        var match = true;
        for (needle, 0..) |c, j| {
            if (haystack[i + j] != c) {
                match = false;
                break;
            }
        }
        if (match) return true;
    }

    return false;
}

// Helper to get keyword count
export fn getKeywordCount() i32 {
    return KEYWORDS.len;
}

// Helper to get keyword at index (for inspection)
export fn getKeyword(index: usize, out_ptr: [*]u8) usize {
    if (index >= KEYWORDS.len) return 0;

    const keyword = KEYWORDS[index];
    for (keyword, 0..) |c, i| {
        out_ptr[i] = c;
    }

    return keyword.len;
}
