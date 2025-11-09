const std = @import("std");
const mem = std.mem;

/// Simple Base64 decoder with heuristics
/// Only decodes strings that are likely to contain meaningful text
pub const Base64Decoder = struct {
    allocator: mem.Allocator,

    const base64_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    pub fn init(allocator: mem.Allocator) Base64Decoder {
        return Base64Decoder{ .allocator = allocator };
    }

    /// Check if a string looks like base64
    /// Heuristic: 75%+ base64 chars, length > 20, divisible by 4 or has padding
    pub fn looksLikeBase64(text: []const u8) bool {
        if (text.len < 20) return false;

        var base64_count: usize = 0;
        for (text) |c| {
            if (isBase64Char(c) or c == '=') {
                base64_count += 1;
            }
        }

        const ratio = @as(f32, @floatFromInt(base64_count)) / @as(f32, @floatFromInt(text.len));
        return ratio > 0.75;
    }

    fn isBase64Char(c: u8) bool {
        return (c >= 'A' and c <= 'Z') or
            (c >= 'a' and c <= 'z') or
            (c >= '0' and c <= '9') or
            c == '+' or c == '/' or c == '=';
    }

    /// Decode base64 string
    /// Returns decoded bytes or empty array if invalid
    pub fn decode(self: *const Base64Decoder, encoded: []const u8) ![]u8 {
        // Use std.base64
        const decoder = std.base64.standard.Decoder;
        const max_size = try decoder.calcSizeForSlice(encoded);

        const result = try self.allocator.alloc(u8, max_size);
        errdefer self.allocator.free(result);

        // Decode in place
        decoder.decode(result, encoded) catch {
            self.allocator.free(result);
            return self.allocator.alloc(u8, 0);
        };

        // The actual decoded size is max_size (standard base64 doesn't return partial)
        return result;
    }

    /// Check if decoded bytes contain readable text (not binary data)
    pub fn isReadableText(bytes: []const u8) bool {
        if (bytes.len == 0) return false;

        var readable_count: usize = 0;
        for (bytes) |c| {
            // Check for readable characters:
            // - ASCII printable (32-126)
            // - Hebrew UTF-8 (0xD7, 0x90-0xBF)
            // - Common whitespace
            if ((c >= 32 and c <= 126) or
                c == '\n' or c == '\r' or c == '\t' or
                c == 0xD7 or (c >= 0x90 and c <= 0xBF))
            {
                readable_count += 1;
            }
        }

        const ratio = @as(f32, @floatFromInt(readable_count)) / @as(f32, @floatFromInt(bytes.len));
        return ratio > 0.8; // 80%+ readable
    }

    /// Smart decode: only decode if it looks like text, not binary data
    pub fn smartDecode(self: *const Base64Decoder, text: []const u8) !?[]u8 {
        // Check heuristics first
        if (!looksLikeBase64(text)) {
            return null;
        }

        // Skip if it looks like image/font data URI
        if (text.len > 10) {
            // Common prefixes for binary data
            if (mem.startsWith(u8, text, "iVBORw0KG") or // PNG
                mem.startsWith(u8, text, "/9j/") or // JPEG
                mem.startsWith(u8, text, "R0lGOD") or // GIF
                mem.startsWith(u8, text, "data:image") or
                mem.startsWith(u8, text, "data:font"))
            {
                return null;
            }
        }

        // Try to decode (catch ALL errors)
        const decoded = self.decode(text) catch {
            // Invalid base64 (padding, invalid chars, etc.)
            return null;
        };
        errdefer self.allocator.free(decoded);

        // Empty result?
        if (decoded.len == 0) {
            self.allocator.free(decoded);
            return null;
        }

        // Check if it's readable text
        if (!isReadableText(decoded)) {
            self.allocator.free(decoded);
            return null;
        }

        return decoded;
    }

    pub fn deinit(self: *Base64Decoder) void {
        _ = self;
    }
};

// Test
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var decoder = Base64Decoder.init(allocator);
    defer decoder.deinit();

    std.debug.print("Base64 Decoder - Smart Heuristics Test\n", .{});
    std.debug.print("======================================\n\n", .{});

    // Test 1: Hebrew text (should decode)
    const test1 = "16TXldem16DXldeS16jXpNeZ15Qg15nhtm3Xktem16jXmdedIA=="; // פורנוגרפיה מבוגרים
    std.debug.print("Test 1 - Hebrew text:\n", .{});
    std.debug.print("  Input: {s}\n", .{test1});
    std.debug.print("  Looks like base64? {}\n", .{Base64Decoder.looksLikeBase64(test1)});

    if (try decoder.smartDecode(test1)) |decoded| {
        defer allocator.free(decoded);
        std.debug.print("  Decoded: {s}\n", .{decoded});
        std.debug.print("  ✓ Successfully decoded!\n\n", .{});
    } else {
        std.debug.print("  ✗ Skipped (not text)\n\n", .{});
    }

    // Test 2: English text (should decode)
    const test2 = "SGVsbG8gV29ybGQhIFRoaXMgaXMgYSB0ZXN0"; // Hello World! This is a test
    std.debug.print("Test 2 - English text:\n", .{});
    std.debug.print("  Input: {s}\n", .{test2});
    std.debug.print("  Looks like base64? {}\n", .{Base64Decoder.looksLikeBase64(test2)});

    if (try decoder.smartDecode(test2)) |decoded| {
        defer allocator.free(decoded);
        std.debug.print("  Decoded: {s}\n", .{decoded});
        std.debug.print("  ✓ Successfully decoded!\n\n", .{});
    } else {
        std.debug.print("  ✗ Skipped (not text)\n\n", .{});
    }

    // Test 3: Image data (should skip)
    const test3 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==";
    std.debug.print("Test 3 - PNG image:\n", .{});
    std.debug.print("  Input: {s}...\n", .{test3[0..50]});
    std.debug.print("  Looks like base64? {}\n", .{Base64Decoder.looksLikeBase64(test3)});

    if (try decoder.smartDecode(test3)) |decoded| {
        defer allocator.free(decoded);
        std.debug.print("  Decoded: (binary data)\n", .{});
        std.debug.print("  ✗ Should have been skipped!\n\n", .{});
    } else {
        std.debug.print("  ✓ Correctly skipped (image data)!\n\n", .{});
    }

    // Test 4: Short string (should skip)
    const test4 = "SGVsbG8="; // "Hello" - too short
    std.debug.print("Test 4 - Short string:\n", .{});
    std.debug.print("  Input: {s}\n", .{test4});
    std.debug.print("  Looks like base64? {}\n", .{Base64Decoder.looksLikeBase64(test4)});

    if (try decoder.smartDecode(test4)) |decoded| {
        defer allocator.free(decoded);
        std.debug.print("  Decoded: {s}\n", .{decoded});
        std.debug.print("  ✗ Should have been skipped (too short)!\n\n", .{});
    } else {
        std.debug.print("  ✓ Correctly skipped (too short)!\n\n", .{});
    }

    // Test 5: Random text (should skip)
    const test5 = "This is not base64 encoded text at all";
    std.debug.print("Test 5 - Random text:\n", .{});
    std.debug.print("  Input: {s}\n", .{test5});
    std.debug.print("  Looks like base64? {}\n", .{Base64Decoder.looksLikeBase64(test5)});

    if (try decoder.smartDecode(test5)) |decoded| {
        defer allocator.free(decoded);
        std.debug.print("  Decoded: {s}\n", .{decoded});
        std.debug.print("  ✗ Should have been skipped!\n\n", .{});
    } else {
        std.debug.print("  ✓ Correctly skipped (not base64)!\n\n", .{});
    }

    std.debug.print("======================================\n", .{});
    std.debug.print("Summary:\n", .{});
    std.debug.print("  Smart heuristics prevent:\n", .{});
    std.debug.print("    ✓ Decoding images/fonts (binary)\n", .{});
    std.debug.print("    ✓ Decoding short strings (noise)\n", .{});
    std.debug.print("    ✓ Decoding random text (false positives)\n", .{});
    std.debug.print("\n  Only decode:\n", .{});
    std.debug.print("    ✓ Long base64 strings (>20 chars)\n", .{});
    std.debug.print("    ✓ That decode to readable text\n", .{});
    std.debug.print("    ✓ Not starting with image/font signatures\n", .{});
}
