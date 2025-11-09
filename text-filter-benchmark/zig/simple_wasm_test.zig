const std = @import("std");

// Simple function for WASM test
export fn detectKeyword(text_ptr: [*]const u8, text_len: usize) i32 {
    const text = text_ptr[0..text_len];

    // Keywords to search for (including base64!)
    const keywords = [_][]const u8{
        "פורנוגרפיה",              // Hebrew
        "16TXldem16DXldeS16jXpNeZ15Qg",  // Base64 of "פורנוגרפיה"
        "הימורים",
        "15TXmdee15XXldeo15nXnQ==",      // Base64 of "הימורים"
    };

    var count: i32 = 0;
    for (keywords) |keyword| {
        if (std.mem.indexOf(u8, text, keyword) != null) {
            count += 1;
        }
    }

    return count;
}

// Export memory for JS to access
export var memory: [1024]u8 = undefined;

// For testing: function that returns a sensitive keyword
export fn getSensitiveKeyword() [*]const u8 {
    const keyword = "פורנוגרפיה למבוגרים";
    return keyword.ptr;
}
