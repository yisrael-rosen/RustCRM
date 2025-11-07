const std = @import("std");

/// HTML Parser for extracting text content from HTML documents
pub const HtmlParser = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) HtmlParser {
        return HtmlParser{
            .allocator = allocator,
        };
    }

    /// Extract all visible text from HTML, removing tags, scripts, and styles
    pub fn extractText(self: *const HtmlParser, html: []const u8) ![]u8 {
        var result = std.ArrayList(u8).init(self.allocator);
        errdefer result.deinit();

        var i: usize = 0;
        var in_tag = false;
        var in_script = false;
        var in_style = false;
        var last_was_space = false;

        while (i < html.len) {
            const ch = html[i];

            if (ch == '<') {
                in_tag = true;

                // Check for script or style tags
                if (i + 7 < html.len and std.mem.eql(u8, html[i..i+7], "<script")) {
                    in_script = true;
                } else if (i + 6 < html.len and std.mem.eql(u8, html[i..i+6], "<style")) {
                    in_style = true;
                } else if (i + 9 < html.len and std.mem.eql(u8, html[i..i+9], "</script>")) {
                    in_script = false;
                    i += 8; // Skip the closing tag
                } else if (i + 8 < html.len and std.mem.eql(u8, html[i..i+8], "</style>")) {
                    in_style = false;
                    i += 7; // Skip the closing tag
                }
                i += 1;
                continue;
            }

            if (ch == '>') {
                in_tag = false;
                // Add space after tags to separate words
                if (result.items.len > 0 and !last_was_space) {
                    try result.append(' ');
                    last_was_space = true;
                }
                i += 1;
                continue;
            }

            // Skip content inside tags, scripts, and styles
            if (in_tag or in_script or in_style) {
                i += 1;
                continue;
            }

            // Handle whitespace
            if (std.ascii.isWhitespace(ch)) {
                if (!last_was_space and result.items.len > 0) {
                    try result.append(' ');
                    last_was_space = true;
                }
                i += 1;
                continue;
            }

            // Add regular character
            try result.append(ch);
            last_was_space = false;
            i += 1;
        }

        return result.toOwnedSlice();
    }

    /// Extract text from specific HTML tag types (e.g., "p", "h1", "div")
    pub fn extractFromTag(self: *const HtmlParser, html: []const u8, tag_name: []const u8) !std.ArrayList([]u8) {
        var results = std.ArrayList([]u8).init(self.allocator);
        errdefer {
            for (results.items) |item| {
                self.allocator.free(item);
            }
            results.deinit();
        }

        // Create opening and closing tags
        var opening_tag = try std.ArrayList(u8).initCapacity(self.allocator, tag_name.len + 2);
        defer opening_tag.deinit();
        try opening_tag.append('<');
        try opening_tag.appendSlice(tag_name);

        var closing_tag = try std.ArrayList(u8).initCapacity(self.allocator, tag_name.len + 3);
        defer closing_tag.deinit();
        try closing_tag.appendSlice("</");
        try closing_tag.appendSlice(tag_name);
        try closing_tag.append('>');

        var i: usize = 0;
        while (i < html.len) {
            // Find opening tag
            if (std.mem.indexOf(u8, html[i..], opening_tag.items)) |start_offset| {
                const start = i + start_offset;
                // Find end of opening tag
                if (std.mem.indexOf(u8, html[start..], ">")) |end_tag_offset| {
                    const content_start = start + end_tag_offset + 1;
                    // Find closing tag
                    if (std.mem.indexOf(u8, html[content_start..], closing_tag.items)) |end_offset| {
                        const content_end = content_start + end_offset;
                        const tag_content = html[content_start..content_end];

                        // Extract text from the tag content (recursively remove nested tags)
                        const text = try self.extractText(tag_content);
                        try results.append(text);

                        i = content_end + closing_tag.items.len;
                        continue;
                    }
                }
            }
            i += 1;
        }

        return results;
    }

    /// Free text extracted by extractFromTag
    pub fn freeExtractedTexts(self: *const HtmlParser, texts: *std.ArrayList([]u8)) void {
        for (texts.items) |text| {
            self.allocator.free(text);
        }
        texts.deinit();
    }
};

// Tests
test "extract basic text" {
    const allocator = std.testing.allocator;
    const parser = HtmlParser.init(allocator);

    const html = "<html><body><p>שלום עולם</p></body></html>";
    const text = try parser.extractText(html);
    defer allocator.free(text);

    try std.testing.expect(std.mem.indexOf(u8, text, "שלום עולם") != null);
}

test "remove script tags" {
    const allocator = std.testing.allocator;
    const parser = HtmlParser.init(allocator);

    const html = "<html><head><script>alert('test');</script></head><body>טקסט נקי</body></html>";
    const text = try parser.extractText(html);
    defer allocator.free(text);

    try std.testing.expect(std.mem.indexOf(u8, text, "טקסט נקי") != null);
    try std.testing.expect(std.mem.indexOf(u8, text, "alert") == null);
}

test "remove style tags" {
    const allocator = std.testing.allocator;
    const parser = HtmlParser.init(allocator);

    const html = "<html><head><style>body { color: red; }</style></head><body>תוכן</body></html>";
    const text = try parser.extractText(html);
    defer allocator.free(text);

    try std.testing.expect(std.mem.indexOf(u8, text, "תוכן") != null);
    try std.testing.expect(std.mem.indexOf(u8, text, "color") == null);
}

test "extract from specific tag" {
    const allocator = std.testing.allocator;
    const parser = HtmlParser.init(allocator);

    const html = "<html><body><h1>כותרת</h1><p>פסקה</p><h1>כותרת נוספת</h1></body></html>";
    var headers = try parser.extractFromTag(html, "h1");
    defer parser.freeExtractedTexts(&headers);

    try std.testing.expectEqual(@as(usize, 2), headers.items.len);
    try std.testing.expect(std.mem.indexOf(u8, headers.items[0], "כותרת") != null);
    try std.testing.expect(std.mem.indexOf(u8, headers.items[1], "כותרת נוספת") != null);
}
