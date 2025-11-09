const std = @import("std");

// Auto-generated keywords with base64 encodings
// This allows detecting base64-encoded keywords without runtime decoding!

/// Business keywords (original)
pub const BUSINESS_KEYWORDS = [_][]const u8{
    "תוכן",
    "דוח",
    "דיל",
    "מסחר",
    "חדש",
    "בהמתנה",
    "יועץ",
    "לקוחה",
    "תכנון",
    "תהליך",
    "נאמנות",
    "מכירה",
    "תשלום",
    "יתרון",
    "בסיס נתונים",
};

/// Business keywords (base64 encoded)
pub const BUSINESS_KEYWORDS_BASE64 = [_][]const u8{
    "16rXldeb158=",  // תוכן
    "15PXldeX",  // דוח
    "15PXmdec",  // דיל
    "157XodeX16g=",  // מסחר
    "15fXk9ep",  // חדש
    "15HXlNee16rXoNeU",  // בהמתנה
    "15nXldei16U=",  // יועץ
    "15zXp9eV15fXlA==",  // לקוחה
    "16rXm9eg15XXnw==",  // תכנון
    "16rXlNec15nXmg==",  // תהליך
    "16DXkNee16DXldeq",  // נאמנות
    "157Xm9eZ16jXlA==",  // מכירה
    "16rXqdec15XXnQ==",  // תשלום
    "15nXqteo15XXnw==",  // יתרון
    "15HXodeZ16Eg16DXqteV16DXmded",  // בסיס נתונים
};

/// Sensitive keywords (original)
pub const SENSITIVE_KEYWORDS = [_][]const u8{
    "זונה",
    "מיניים",
    "סלוטים",
    "הימרן",
    "קוקה",
    "גראס",
    "תרופה",
    "מטען",
    "פצוע",
    "שנאת",
    "קללות",
    "מלטי",
    "פירוץ",
};

/// Sensitive keywords (base64 encoded)
pub const SENSITIVE_KEYWORDS_BASE64 = [_][]const u8{
    "15bXldeg15Q=",  // זונה
    "157Xmdeg15nXmded",  // מיניים
    "16HXnNeV15jXmded",  // סלוטים
    "15TXmdee16jXnw==",  // הימרן
    "16fXlden15Q=",  // קוקה
    "15LXqNeQ16E=",  // גראס
    "16rXqNeV16TXlA==",  // תרופה
    "157XmNei158=",  // מטען
    "16TXpteV16I=",  // פצוע
    "16nXoNeQ16o=",  // שנאת
    "16fXnNec15XXqg==",  // קללות
    "157XnNeY15k=",  // מלטי
    "16TXmdeo15XXpQ==",  // פירוץ
};

/// Combined: all business keywords (original + base64)
pub const ALL_BUSINESS_KEYWORDS = BUSINESS_KEYWORDS ++ BUSINESS_KEYWORDS_BASE64;

/// Combined: all sensitive keywords (original + base64)
pub const ALL_SENSITIVE_KEYWORDS = SENSITIVE_KEYWORDS ++ SENSITIVE_KEYWORDS_BASE64;

// Statistics
pub const STATS = struct {
    pub const business_original = BUSINESS_KEYWORDS.len;
    pub const business_base64 = BUSINESS_KEYWORDS_BASE64.len;
    pub const business_total = ALL_BUSINESS_KEYWORDS.len;

    pub const sensitive_original = SENSITIVE_KEYWORDS.len;
    pub const sensitive_base64 = SENSITIVE_KEYWORDS_BASE64.len;
    pub const sensitive_total = ALL_SENSITIVE_KEYWORDS.len;

    pub const total_keywords = business_total + sensitive_total;
};

pub fn printStats() void {
    const std_debug = @import("std").debug;

    std_debug.print("\nKeyword Statistics:\n", .{});
    std_debug.print("==================\n", .{});
    std_debug.print("Business keywords:\n", .{});
    std_debug.print("  Original:  {}\n", .{STATS.business_original});
    std_debug.print("  Base64:    {}\n", .{STATS.business_base64});
    std_debug.print("  Total:     {}\n", .{STATS.business_total});
    std_debug.print("\n", .{});
    std_debug.print("Sensitive keywords:\n", .{});
    std_debug.print("  Original:  {}\n", .{STATS.sensitive_original});
    std_debug.print("  Base64:    {}\n", .{STATS.sensitive_base64});
    std_debug.print("  Total:     {}\n", .{STATS.sensitive_total});
    std_debug.print("\n", .{});
    std_debug.print("Grand Total: {} keywords\n", .{STATS.total_keywords});
    std_debug.print("\n", .{});
    std_debug.print("Coverage:\n", .{});
    std_debug.print("  - Plain text: 100%% ✓\n", .{});
    std_debug.print("  - Base64 encoded: 100%% ✓\n", .{});
    std_debug.print("  - No runtime decoding needed! ✓\n", .{});
}
