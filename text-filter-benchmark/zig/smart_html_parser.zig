const std = @import("std");
const mem = std.mem;

/// Smart HTML Parser - Extracts text AND strings from JavaScript
/// More accurate than blind scanning, faster than full JS parsing
pub const SmartHtmlParser = struct {
    allocator: mem.Allocator,

    pub fn init(allocator: mem.Allocator) SmartHtmlParser {
        return SmartHtmlParser{ .allocator = allocator };
    }

    /// Extract text from HTML + strings from JavaScript/JSON + attribute values
    pub fn extractContent(self: *const SmartHtmlParser, html: []const u8) ![]u8 {
        var result = std.ArrayList(u8).init(self.allocator);
        errdefer result.deinit();

        var i: usize = 0;
        var in_tag = false;
        var in_script = false;
        var in_style = false;
        var script_start: ?usize = null;
        var tag_content = std.ArrayList(u8).init(self.allocator);
        defer tag_content.deinit();

        while (i < html.len) {
            // Detect <script> tags
            if (i + 7 <= html.len and mem.eql(u8, html[i .. i + 7], "<script")) {
                in_script = true;
                in_tag = true;
                script_start = null;
            }

            // Find end of opening <script> tag
            if (in_script and script_start == null and html[i] == '>') {
                script_start = i + 1;
                in_tag = false;
                i += 1;
                continue;
            }

            // Detect </script> - process accumulated script content
            if (i + 9 <= html.len and mem.eql(u8, html[i .. i + 9], "</script>")) {
                if (in_script) {
                    if (script_start) |start_pos| {
                        const js_code = html[start_pos..i];
                        // Extract strings from JavaScript
                        const js_strings = try self.extractJsStrings(js_code);
                        defer self.allocator.free(js_strings);

                        if (js_strings.len > 0) {
                            try result.appendSlice(js_strings);
                            try result.append(' ');
                        }
                    }
                }
                in_script = false;
                script_start = null;
                i += 9;
                continue;
            }

            // Detect <style> tags
            if (i + 6 <= html.len and mem.eql(u8, html[i .. i + 6], "<style")) {
                in_style = true;
                in_tag = true;
            }

            // Detect </style>
            if (i + 8 <= html.len and mem.eql(u8, html[i .. i + 8], "</style>")) {
                in_style = false;
                i += 8;
                continue;
            }

            // Detect tag start
            if (html[i] == '<' and !in_script) {
                in_tag = true;
                tag_content.clearRetainingCapacity();
            }

            // Accumulate tag content (for attribute extraction)
            if (in_tag and !in_script and !in_style) {
                try tag_content.append(html[i]);
            }

            // Detect tag end
            if (html[i] == '>' and in_tag and !in_script and !in_style) {
                // Extract attribute values from this tag
                const attr_values = try self.extractAttributeValues(tag_content.items);
                defer self.allocator.free(attr_values);

                if (attr_values.len > 0) {
                    try result.appendSlice(attr_values);
                    try result.append(' ');
                }

                in_tag = false;
                i += 1;
                continue;
            }

            // Skip inside scripts and styles
            if (in_script or in_style) {
                i += 1;
                continue;
            }

            // Skip tags
            if (in_tag) {
                i += 1;
                continue;
            }

            // Regular text content
            const c = html[i];

            // Normalize whitespace
            if (c == ' ' or c == '\t' or c == '\n' or c == '\r') {
                if (result.items.len > 0 and result.items[result.items.len - 1] != ' ') {
                    try result.append(' ');
                }
            } else {
                try result.append(c);
            }

            i += 1;
        }

        return result.toOwnedSlice();
    }

    /// Extract string literals from JavaScript code
    /// Handles: "...", '...', `...` (template literals)
    fn extractJsStrings(self: *const SmartHtmlParser, js_code: []const u8) ![]u8 {
        var result = std.ArrayList(u8).init(self.allocator);
        errdefer result.deinit();

        var i: usize = 0;
        while (i < js_code.len) {
            const c = js_code[i];

            // Double quotes
            if (c == '"') {
                i += 1;
                const str = try self.extractStringUntil(js_code, &i, '"');
                try result.appendSlice(str);
                try result.append(' ');
                continue;
            }

            // Single quotes
            if (c == '\'') {
                i += 1;
                const str = try self.extractStringUntil(js_code, &i, '\'');
                try result.appendSlice(str);
                try result.append(' ');
                continue;
            }

            // Template literals (backticks)
            if (c == '`') {
                i += 1;
                const str = try self.extractStringUntil(js_code, &i, '`');
                try result.appendSlice(str);
                try result.append(' ');
                continue;
            }

            i += 1;
        }

        return result.toOwnedSlice();
    }

    /// Extract string content until delimiter (handling escapes)
    fn extractStringUntil(self: *const SmartHtmlParser, text: []const u8, pos: *usize, delimiter: u8) ![]u8 {
        var result = std.ArrayList(u8).init(self.allocator);
        errdefer result.deinit();

        var i = pos.*;
        while (i < text.len) {
            const c = text[i];

            // Check for escaped delimiter
            if (c == '\\' and i + 1 < text.len) {
                const next = text[i + 1];
                if (next == delimiter or next == '\\') {
                    // Add the escaped character
                    try result.append(next);
                    i += 2;
                    continue;
                }
            }

            // Found closing delimiter
            if (c == delimiter) {
                pos.* = i + 1;
                return result.toOwnedSlice();
            }

            try result.append(c);
            i += 1;
        }

        // String not closed (malformed) - return what we have
        pos.* = i;
        return result.toOwnedSlice();
    }

    /// Extract attribute values (for data-*, onclick, etc.)
    pub fn extractAttributeValues(self: *const SmartHtmlParser, html: []const u8) ![]u8 {
        var result = std.ArrayList(u8).init(self.allocator);
        errdefer result.deinit();

        var i: usize = 0;
        while (i < html.len) {
            // Look for attributes: attr="value" or attr='value'
            if (html[i] == '=') {
                i += 1;
                // Skip whitespace
                while (i < html.len and (html[i] == ' ' or html[i] == '\t')) {
                    i += 1;
                }

                if (i < html.len) {
                    const quote = html[i];
                    if (quote == '"' or quote == '\'') {
                        i += 1;
                        const value = try self.extractStringUntil(html, &i, quote);
                        defer self.allocator.free(value);

                        // Only add if it's meaningful content (not just URLs, numbers, etc.)
                        if (value.len > 3) {
                            try result.appendSlice(value);
                            try result.append(' ');
                        }
                        continue;
                    }
                }
            }
            i += 1;
        }

        return result.toOwnedSlice();
    }

    pub fn deinit(self: *SmartHtmlParser) void {
        _ = self;
    }
};

// Simple test
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const test_html =
        \\<html>
        \\<body>
        \\<h1>כותרת רגילה</h1>
        \\<script>
        \\var message = "זה תוכן מוסתר בJS";
        \\const data = {
        \\  content: "מידע רגיש בJSON",
        \\  title: 'עוד מחרוזת'
        \\};
        \\var template = `תבנית עם ${variable}`;
        \\</script>
        \\<div data-content="תוכן בdata attribute">
        \\  טקסט רגיל
        \\</div>
        \\<button onclick="alert('הודעה')">לחץ</button>
        \\</body>
        \\</html>
    ;

    var parser = SmartHtmlParser.init(allocator);
    defer parser.deinit();

    std.debug.print("Testing Smart HTML Parser\n", .{});
    std.debug.print("========================\n\n", .{});
    std.debug.print("Input HTML:\n{s}\n\n", .{test_html});
    std.debug.print("========================\n\n", .{});

    // Extract all content (text + JS strings + attributes)
    const content = try parser.extractContent(test_html);
    defer allocator.free(content);

    std.debug.print("Extracted content (all combined):\n{s}\n\n", .{content});
    std.debug.print("========================\n", .{});
    std.debug.print("Content includes:\n", .{});
    std.debug.print("  ✓ Regular HTML text\n", .{});
    std.debug.print("  ✓ Strings from <script> tags\n", .{});
    std.debug.print("  ✓ Attribute values (data-*, onclick, etc.)\n", .{});
    std.debug.print("  ✗ JavaScript code (removed)\n", .{});
    std.debug.print("  ✗ HTML tags (removed)\n", .{});
    std.debug.print("  ✗ CSS (removed)\n", .{});
}
