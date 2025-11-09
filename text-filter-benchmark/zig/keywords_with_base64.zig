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

/// Business keywords (base64 encoded - 3 alignment variants each)
/// Each keyword has 3 variants to handle different base64 chunk alignments
/// This solves the "alignment problem" where keywords can be split across base64 boundaries
pub const BUSINESS_KEYWORDS_BASE64 = [_][]const u8{
    "16rXldeb158",  // תוכן (align 0)
    "eq15XXm9ef",  // תוכן (align 1)
    "XqteV15vXnw",  // תוכן (align 2)
    "15PXldeX",  // דוח (align 0)
    "eT15XXlw",  // דוח (align 1)
    "Xk9eV15c",  // דוח (align 2)
    "15PXmdec",  // דיל (align 0)
    "eT15nXnA",  // דיל (align 1)
    "Xk9eZ15w",  // דיל (align 2)
    "157XodeX16g",  // מסחר (align 0)
    "ee16HXl9eo",  // מסחר (align 1)
    "Xnteh15fXqA",  // מסחר (align 2)
    "15fXk9ep",  // חדש (align 0)
    "eX15PXqQ",  // חדש (align 1)
    "Xl9eT16k",  // חדש (align 2)
    "15HXlNee16rXoNeU",  // בהמתנה (align 0)
    "eR15TXnteq16DXlA",  // בהמתנה (align 1)
    "XkdeU157Xqteg15Q",  // בהמתנה (align 2)
    "15nXldei16U",  // יועץ (align 0)
    "eZ15XXotel",  // יועץ (align 1)
    "XmdeV16LXpQ",  // יועץ (align 2)
    "15zXp9eV15fXlA",  // לקוחה (align 0)
    "ec16fXldeX15Q",  // לקוחה (align 1)
    "XnNen15XXl9eU",  // לקוחה (align 2)
    "16rXm9eg15XXnw",  // תכנון (align 0)
    "eq15vXoNeV158",  // תכנון (align 1)
    "Xqteb16DXldef",  // תכנון (align 2)
    "16rXlNec15nXmg",  // תהליך (align 0)
    "eq15TXnNeZ15o",  // תהליך (align 1)
    "XqteU15zXmdea",  // תהליך (align 2)
    "16DXkNee16DXldeq",  // נאמנות (align 0)
    "eg15DXnteg15XXqg",  // נאמנות (align 1)
    "XoNeQ157XoNeV16o",  // נאמנות (align 2)
    "157Xm9eZ16jXlA",  // מכירה (align 0)
    "ee15vXmdeo15Q",  // מכירה (align 1)
    "Xnteb15nXqNeU",  // מכירה (align 2)
    "16rXqdec15XXnQ",  // תשלום (align 0)
    "eq16nXnNeV150",  // תשלום (align 1)
    "Xqtep15zXlded",  // תשלום (align 2)
    "15nXqteo15XXnw",  // יתרון (align 0)
    "eZ16rXqNeV158",  // יתרון (align 1)
    "Xmdeq16jXldef",  // יתרון (align 2)
    "15HXodeZ16Eg16DXqteV16DXmded",  // בסיס נתונים (align 0)
    "eR16HXmdehINeg16rXldeg15nXnQ",  // בסיס נתונים (align 1)
    "Xkdeh15nXoSDXoNeq15XXoNeZ150",  // בסיס נתונים (align 2)
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

/// Sensitive keywords (base64 encoded - 3 alignment variants each)
/// Each keyword has 3 variants to handle different base64 chunk alignments
/// This solves the "alignment problem" where keywords can be split across base64 boundaries
pub const SENSITIVE_KEYWORDS_BASE64 = [_][]const u8{
    "15bXldeg15Q",  // זונה (align 0)
    "eW15XXoNeU",  // זונה (align 1)
    "XlteV16DXlA",  // זונה (align 2)
    "157Xmdeg15nXmded",  // מיניים (align 0)
    "ee15nXoNeZ15nXnQ",  // מיניים (align 1)
    "XnteZ16DXmdeZ150",  // מיניים (align 2)
    "16HXnNeV15jXmded",  // סלוטים (align 0)
    "eh15zXldeY15nXnQ",  // סלוטים (align 1)
    "Xodec15XXmNeZ150",  // סלוטים (align 2)
    "15TXmdee16jXnw",  // הימרן (align 0)
    "eU15nXnteo158",  // הימרן (align 1)
    "XlNeZ157XqNef",  // הימרן (align 2)
    "16fXlden15Q",  // קוקה (align 0)
    "en15XXp9eU",  // קוקה (align 1)
    "Xp9eV16fXlA",  // קוקה (align 2)
    "15LXqNeQ16E",  // גראס (align 0)
    "eS16jXkNeh",  // גראס (align 1)
    "Xkteo15DXoQ",  // גראס (align 2)
    "16rXqNeV16TXlA",  // תרופה (align 0)
    "eq16jXldek15Q",  // תרופה (align 1)
    "Xqteo15XXpNeU",  // תרופה (align 2)
    "157XmNei158",  // מטען (align 0)
    "ee15jXotef",  // מטען (align 1)
    "XnteY16LXnw",  // מטען (align 2)
    "16TXpteV16I",  // פצוע (align 0)
    "ek16bXldei",  // פצוע (align 1)
    "XpNem15XXog",  // פצוע (align 2)
    "16nXoNeQ16o",  // שנאת (align 0)
    "ep16DXkNeq",  // שנאת (align 1)
    "Xqdeg15DXqg",  // שנאת (align 2)
    "16fXnNec15XXqg",  // קללות (align 0)
    "en15zXnNeV16o",  // קללות (align 1)
    "Xp9ec15zXldeq",  // קללות (align 2)
    "157XnNeY15k",  // מלטי (align 0)
    "ee15zXmNeZ",  // מלטי (align 1)
    "Xntec15jXmQ",  // מלטי (align 2)
    "16TXmdeo15XXpQ",  // פירוץ (align 0)
    "ek15nXqNeV16U",  // פירוץ (align 1)
    "XpNeZ16jXldel",  // פירוץ (align 2)
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
