const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const time = std.time;

// ============================================================================
// ULTIMATE CONTENT CLASSIFIER - Full Production Version
// ============================================================================
// Combines ALL features:
// ✅ 400 base keywords (200 business + 200 sensitive)
// ✅ Hebrew inflections support (×7 forms via suffix matching)
// ✅ Weighted keywords (0.1-10.0)
// ✅ Context window analysis
// ✅ Co-occurrence patterns
// ✅ Proximity scoring
// ✅ HTML parsing
// ✅ Performance metrics
//
// Goal: 85%+ LLM reduction with high accuracy
// ============================================================================

// ============================================================================
// BUSINESS KEYWORDS (200 base words)
// ============================================================================

const BUSINESS_KEYWORDS = [_]WeightedKeyword{
    // קטגוריה 1: תקשורת ומידע (20 מילים) - Weight: 2.0
    .{ .word = "מידע", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "נתונים", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "דיווח", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "עדכון", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "הודעה", .weight = 1.5, .category = .CLEAR_BUSINESS },
    .{ .word = "תקשורת", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "מסמך", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "טופס", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "קובץ", .weight = 1.5, .category = .CLEAR_BUSINESS },
    .{ .word = "דוח", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "פרטים", .weight = 1.5, .category = .CLEAR_BUSINESS },
    .{ .word = "תיאור", .weight = 1.5, .category = .CLEAR_BUSINESS },
    .{ .word = "הסבר", .weight = 1.5, .category = .CLEAR_BUSINESS },
    .{ .word = "תוכן", .weight = 1.0, .category = .AMBIGUOUS_BUSINESS }, // can be "adult content"
    .{ .word = "מסר", .weight = 1.5, .category = .CLEAR_BUSINESS },
    .{ .word = "הנחיה", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "הוראה", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "התראה", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "אזהרה", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "הערה", .weight = 1.5, .category = .CLEAR_BUSINESS },

    // קטגוריה 2: CRM ומכירות (30 מילים) - Weight: 3.0-5.0
    .{ .word = "לקוח", .weight = 5.0, .category = .VERY_CLEAR_BUSINESS },
    .{ .word = "לקוחה", .weight = 5.0, .category = .VERY_CLEAR_BUSINESS },
    .{ .word = "קונה", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "רוכש", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "ליד", .weight = 5.0, .category = .VERY_CLEAR_BUSINESS },
    .{ .word = "לידים", .weight = 5.0, .category = .VERY_CLEAR_BUSINESS },
    .{ .word = "הזדמנות", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "pipeline", .weight = 5.0, .category = .VERY_CLEAR_BUSINESS },
    .{ .word = "משפך", .weight = 4.0, .category = .CLEAR_BUSINESS },
    .{ .word = "המרה", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "סגירה", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "מכירה", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "מכירות", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "מוכר", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "מכר", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "רכישה", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "קניה", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "עסקה", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "דיל", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "הצעה", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "הזמנה", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "חוזה", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "הסכם", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "גיוס", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "שימור", .weight = 4.0, .category = .CLEAR_BUSINESS },
    .{ .word = "נאמנות", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "שביעות רצון", .weight = 4.0, .category = .CLEAR_BUSINESS },
    .{ .word = "משוב", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "ציפיות", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "דרישות", .weight = 2.0, .category = .CLEAR_BUSINESS },

    // קטגוריה 3: ארגון וניהול (30 מילים) - Weight: 2.0-4.0
    .{ .word = "חברה", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "ארגון", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "עסק", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "מנהל", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "ניהול", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "הנהלה", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "מנכל", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "סמנכל", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "מנהיגות", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "צוות", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "עובד", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "עובדים", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "משתמש", .weight = 1.5, .category = .CLEAR_BUSINESS },
    .{ .word = "משתמשים", .weight = 1.5, .category = .CLEAR_BUSINESS },
    .{ .word = "נציג", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "סוכן", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "ספק", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "שותף", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "שותפות", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "משקיע", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "משקיעים", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "יועץ", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "ייעוץ", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "מומחה", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "התמחות", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "מחלקה", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "אגף", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "יחידה", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "תפקיד", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "אחריות", .weight = 2.0, .category = .CLEAR_BUSINESS },

    // קטגוריה 4: פיננסים (30 מילים) - Weight: 2.0-4.0
    .{ .word = "הכנסה", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "הכנסות", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "רווח", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "רווחיות", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "הוצאה", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "הוצאות", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "עלות", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "עלויות", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "מחיר", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "תמחור", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "תקציב", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "תקציבים", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "תשלום", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "תשלומים", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "חשבונית", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "חשבוניות", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "קבלה", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "סכום", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "כסף", .weight = 1.5, .category = .CLEAR_BUSINESS },
    .{ .word = "שווי", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "שוויון", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "השקעה", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "השקעות", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "מימון", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "אשראי", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "הלוואה", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "ריבית", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "מס", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "מיסוי", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "חשבונאות", .weight = 3.0, .category = .CLEAR_BUSINESS },

    // קטגוריה 5: שיווק ומיתוג (30 מילים) - Weight: 2.0-4.0
    .{ .word = "שיווק", .weight = 4.0, .category = .VERY_CLEAR_BUSINESS },
    .{ .word = "קמפיין", .weight = 4.0, .category = .VERY_CLEAR_BUSINESS },
    .{ .word = "פרסום", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "פרסומת", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "מותג", .weight = 4.0, .category = .CLEAR_BUSINESS },
    .{ .word = "ברנד", .weight = 4.0, .category = .CLEAR_BUSINESS },
    .{ .word = "ברנדינג", .weight = 4.0, .category = .VERY_CLEAR_BUSINESS },
    .{ .word = "קידום", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "קהל", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "קהל יעד", .weight = 4.0, .category = .CLEAR_BUSINESS },
    .{ .word = "מוצר", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "מוצרים", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "שירות", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "שירותים", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "ערך", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "יתרון", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "תחרות", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "תחרותי", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "שוק", .weight = 2.0, .category = .AMBIGUOUS_BUSINESS }, // "black market"
    .{ .word = "מגזר", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "ענף", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "תעשייה", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "מסחר", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "מסחרי", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "מכרז", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "הצעת מחיר", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "משא ומתן", .weight = 4.0, .category = .CLEAR_BUSINESS },
    .{ .word = "מו\"מ", .weight = 4.0, .category = .CLEAR_BUSINESS },
    .{ .word = "אסטרטגיה", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "תכנון אסטרטגי", .weight = 4.0, .category = .CLEAR_BUSINESS },

    // קטגוריה 6: טכנולוגיה ומערכות (30 מילים) - Weight: 2.0-4.0
    .{ .word = "מערכת", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "פלטפורמה", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "תוכנה", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "אפליקציה", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "כלי", .weight = 1.5, .category = .CLEAR_BUSINESS },
    .{ .word = "ממשק", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "אינטגרציה", .weight = 4.0, .category = .VERY_CLEAR_BUSINESS },
    .{ .word = "API", .weight = 4.0, .category = .VERY_CLEAR_BUSINESS },
    .{ .word = "בסיס נתונים", .weight = 4.0, .category = .CLEAR_BUSINESS },
    .{ .word = "מסד נתונים", .weight = 4.0, .category = .CLEAR_BUSINESS },
    .{ .word = "שרת", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "ענן", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "קלאוד", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "SaaS", .weight = 4.0, .category = .VERY_CLEAR_BUSINESS },
    .{ .word = "דיגיטלי", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "דיגיטציה", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "אוטומציה", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "אוטומטי", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "אבטחה", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "אבטחת מידע", .weight = 4.0, .category = .CLEAR_BUSINESS },
    .{ .word = "הצפנה", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "גיבוי", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "שחזור", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "ביצועים", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "אופטימיזציה", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "מדידה", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "ניתוח", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "אנליטיקה", .weight = 3.0, .category = .CLEAR_BUSINESS },
    .{ .word = "דשבורד", .weight = 4.0, .category = .VERY_CLEAR_BUSINESS },
    .{ .word = "דוח ביצועים", .weight = 4.0, .category = .CLEAR_BUSINESS },

    // קטגוריה 7: סטטוס ותהליכים (30 מילים) - Weight: 1.5-3.0
    .{ .word = "סטטוס", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "מצב", .weight = 1.5, .category = .CLEAR_BUSINESS },
    .{ .word = "מאושר", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "אישור", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "ממתין", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "המתנה", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "בטיפול", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "טיפול", .weight = 1.0, .category = .AMBIGUOUS_BUSINESS }, // medical treatment
    .{ .word = "הושלם", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "השלמה", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "בוטל", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "ביטול", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "נדחה", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "דחייה", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "פעיל", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "פעילות", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "סגור", .weight = 1.5, .category = .CLEAR_BUSINESS },
    .{ .word = "סגירה", .weight = 1.5, .category = .CLEAR_BUSINESS },
    .{ .word = "פתוח", .weight = 1.5, .category = .CLEAR_BUSINESS },
    .{ .word = "פתיחה", .weight = 1.5, .category = .CLEAR_BUSINESS },
    .{ .word = "חדש", .weight = 1.5, .category = .CLEAR_BUSINESS },
    .{ .word = "טיוטה", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "בבדיקה", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "בדיקה", .weight = 1.5, .category = .CLEAR_BUSINESS },
    .{ .word = "אושר", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "בתהליך", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "תהליך", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "בהמתנה", .weight = 2.0, .category = .CLEAR_BUSINESS },
    .{ .word = "שלב", .weight = 1.5, .category = .CLEAR_BUSINESS },
    .{ .word = "שלבים", .weight = 1.5, .category = .CLEAR_BUSINESS },
};

// ============================================================================
// SENSITIVE KEYWORDS (200 base words with weights)
// ============================================================================

const SENSITIVE_KEYWORDS = [_]WeightedKeyword{
    // קטגוריה 1: תוכן מיני מפורש (30 מילים) - Weight: 5.0-10.0
    .{ .word = "פורנו", .weight = 10.0, .category = .VERY_CLEAR_SENSITIVE },
    .{ .word = "פורנוגרפיה", .weight = 10.0, .category = .VERY_CLEAR_SENSITIVE },
    .{ .word = "xxx", .weight = 10.0, .category = .VERY_CLEAR_SENSITIVE },
    .{ .word = "סקס", .weight = 5.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "מין", .weight = 0.3, .category = .HIGHLY_AMBIGUOUS }, // species vs sex
    .{ .word = "מיני", .weight = 0.3, .category = .HIGHLY_AMBIGUOUS }, // mini vs sexual
    .{ .word = "מיניים", .weight = 0.5, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "מינית", .weight = 0.5, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "ארוטי", .weight = 5.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "ארוטיקה", .weight = 5.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "עירום", .weight = 1.0, .category = .AMBIGUOUS_SENSITIVE }, // art vs porn
    .{ .word = "עריום", .weight = 1.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "זין", .weight = 0.3, .category = .HIGHLY_AMBIGUOUS }, // zine vs profanity
    .{ .word = "כוס", .weight = 0.5, .category = .HIGHLY_AMBIGUOUS },
    .{ .word = "זונה", .weight = 8.0, .category = .VERY_CLEAR_SENSITIVE },
    .{ .word = "זונות", .weight = 8.0, .category = .VERY_CLEAR_SENSITIVE },
    .{ .word = "זנות", .weight = 8.0, .category = .VERY_CLEAR_SENSITIVE },
    .{ .word = "חשפנות", .weight = 6.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "חשפן", .weight = 6.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "חשפנית", .weight = 6.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "מאונן", .weight = 7.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "אוננות", .weight = 7.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "אורגזמה", .weight = 6.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "הומו", .weight = 1.0, .category = .AMBIGUOUS_SENSITIVE }, // homophobia context
    .{ .word = "לסביות", .weight = 1.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "להט\"ב", .weight = 1.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "סקסי", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "sexy", .weight = 5.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "hot", .weight = 1.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "מבוגרים", .weight = 0.5, .category = .HIGHLY_AMBIGUOUS }, // adults or content?

    // קטגוריה 2: הימורים וקזינו (25 מילים) - Weight: 5.0-10.0
    .{ .word = "קזינו", .weight = 10.0, .category = .VERY_CLEAR_SENSITIVE },
    .{ .word = "קזינאות", .weight = 10.0, .category = .VERY_CLEAR_SENSITIVE },
    .{ .word = "הימורים", .weight = 8.0, .category = .VERY_CLEAR_SENSITIVE },
    .{ .word = "הימור", .weight = 6.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "הימרן", .weight = 7.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "הגרלה", .weight = 2.0, .category = .AMBIGUOUS_SENSITIVE }, // lottery can be legal
    .{ .word = "הגרלות", .weight = 2.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "מזל", .weight = 0.3, .category = .HIGHLY_AMBIGUOUS }, // luck vs gambling
    .{ .word = "פוקר", .weight = 7.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "בלקג'ק", .weight = 8.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "רולטה", .weight = 8.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "סלוטים", .weight = 7.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "בינגו", .weight = 5.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "הימר", .weight = 6.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "שחור", .weight = 0.2, .category = .HIGHLY_AMBIGUOUS }, // black market vs color
    .{ .word = "שוק שחור", .weight = 8.0, .category = .VERY_CLEAR_SENSITIVE },
    .{ .word = "משחק מזל", .weight = 6.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "זכייה", .weight = 1.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "לזכות", .weight = 0.5, .category = .HIGHLY_AMBIGUOUS },
    .{ .word = "הימרה", .weight = 6.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "בטינג", .weight = 8.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "ספורט טוטו", .weight = 7.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "טוטו", .weight = 5.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "פעמוניות", .weight = 7.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "גלגל מזל", .weight = 6.0, .category = .CLEAR_SENSITIVE },

    // קטגוריה 3: סמים וסממנים (30 מילים) - Weight: 5.0-10.0
    .{ .word = "סמים", .weight = 7.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "סם", .weight = 0.2, .category = .HIGHLY_AMBIGUOUS }, // symbol vs drug
    .{ .word = "סמוך", .weight = 0.1, .category = .HIGHLY_AMBIGUOUS },
    .{ .word = "קוקאין", .weight = 10.0, .category = .VERY_CLEAR_SENSITIVE },
    .{ .word = "קוקה", .weight = 2.0, .category = .AMBIGUOUS_SENSITIVE }, // coca-cola
    .{ .word = "הרואין", .weight = 10.0, .category = .VERY_CLEAR_SENSITIVE },
    .{ .word = "קנאביס", .weight = 9.0, .category = .VERY_CLEAR_SENSITIVE },
    .{ .word = "מריחואנה", .weight = 9.0, .category = .VERY_CLEAR_SENSITIVE },
    .{ .word = "חשיש", .weight = 9.0, .category = .VERY_CLEAR_SENSITIVE },
    .{ .word = "גראס", .weight = 2.0, .category = .AMBIGUOUS_SENSITIVE }, // grass
    .{ .word = "אקסטזי", .weight = 10.0, .category = .VERY_CLEAR_SENSITIVE },
    .{ .word = "נרקוטי", .weight = 8.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "נרקוטים", .weight = 8.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "מסמם", .weight = 7.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "משרף", .weight = 7.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "דילר", .weight = 6.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "דילרים", .weight = 6.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "סחר בסמים", .weight = 10.0, .category = .VERY_CLEAR_SENSITIVE },
    .{ .word = "LSD", .weight = 10.0, .category = .VERY_CLEAR_SENSITIVE },
    .{ .word = "MDMA", .weight = 10.0, .category = .VERY_CLEAR_SENSITIVE },
    .{ .word = "THC", .weight = 9.0, .category = .VERY_CLEAR_SENSITIVE },
    .{ .word = "מת-אמפטמין", .weight = 10.0, .category = .VERY_CLEAR_SENSITIVE },
    .{ .word = "מת אמפטמין", .weight = 10.0, .category = .VERY_CLEAR_SENSITIVE },
    .{ .word = "אמפטמין", .weight = 8.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "מורפיום", .weight = 7.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "אופיום", .weight = 7.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "פנטניל", .weight = 7.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "התמכרות", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "מכור", .weight = 2.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "גמילה", .weight = 2.0, .category = .AMBIGUOUS_SENSITIVE },

    // קטגוריה 4: תרופות מפוקפקות (15 מילים) - Weight: 1.0-8.0
    .{ .word = "תרופות", .weight = 0.5, .category = .HIGHLY_AMBIGUOUS }, // medicine
    .{ .word = "תרופה", .weight = 0.5, .category = .HIGHLY_AMBIGUOUS },
    .{ .word = "ויאגרה", .weight = 8.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "סיאליס", .weight = 8.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "כדורים", .weight = 0.5, .category = .HIGHLY_AMBIGUOUS },
    .{ .word = "כדור", .weight = 0.3, .category = .HIGHLY_AMBIGUOUS },
    .{ .word = "גלולות", .weight = 0.5, .category = .HIGHLY_AMBIGUOUS },
    .{ .word = "תרופות ללא מרשם", .weight = 7.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "ללא מרשם", .weight = 5.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "תחליף", .weight = 1.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "זיוף", .weight = 6.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "מזויף", .weight = 6.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "הברחה", .weight = 7.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "מוברח", .weight = 7.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "שוק אפור", .weight = 6.0, .category = .CLEAR_SENSITIVE },

    // קטגוריה 5: אלימות וטרור (30 מילים) - Weight: 3.0-9.0
    .{ .word = "אלימות", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE }, // news context
    .{ .word = "נשק", .weight = 2.0, .category = .AMBIGUOUS_SENSITIVE }, // military/news
    .{ .word = "אקדח", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "רובה", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "פצצה", .weight = 5.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "פצצות", .weight = 5.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "טרור", .weight = 2.0, .category = .AMBIGUOUS_SENSITIVE }, // news
    .{ .word = "טרוריסט", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "טרוריזם", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "סכין", .weight = 1.0, .category = .AMBIGUOUS_SENSITIVE }, // kitchen
    .{ .word = "חרב", .weight = 2.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "רימון", .weight = 1.0, .category = .HIGHLY_AMBIGUOUS }, // grenade vs pomegranate
    .{ .word = "מטען", .weight = 5.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "מטען חבלה", .weight = 9.0, .category = .VERY_CLEAR_SENSITIVE },
    .{ .word = "פיגוע", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "פיגועים", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "פיצוץ", .weight = 4.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "פיצוצים", .weight = 4.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "דאעש", .weight = 7.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "ISIS", .weight = 7.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "אל-קאעידה", .weight = 7.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "התאבדות", .weight = 4.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "התאבד", .weight = 4.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "רצח", .weight = 4.0, .category = .AMBIGUOUS_SENSITIVE }, // news/crime
    .{ .word = "רוצח", .weight = 4.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "רציחה", .weight = 4.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "פצוע", .weight = 1.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "נפגע", .weight = 1.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "נפגעים", .weight = 1.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "נפצע", .weight = 1.0, .category = .AMBIGUOUS_SENSITIVE },

    // קטגוריה 6: גזענות ושנאה (20 מילים) - Weight: 3.0-8.0
    .{ .word = "גזענות", .weight = 5.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "גזעני", .weight = 5.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "שנאה", .weight = 2.0, .category = .AMBIGUOUS_SENSITIVE }, // hate speech vs emotion
    .{ .word = "שנאת", .weight = 4.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "אפליה", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "נאצי", .weight = 4.0, .category = .AMBIGUOUS_SENSITIVE }, // history
    .{ .word = "נאצים", .weight = 4.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "נאציזם", .weight = 5.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "פשיזם", .weight = 5.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "פשיסט", .weight = 5.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "קיצוני", .weight = 2.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "קיצונות", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "קיצוניות", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "קנאות", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "קנאי", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "הסתה", .weight = 6.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "מסית", .weight = 6.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "הוקעה", .weight = 2.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "ביזוי", .weight = 4.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "השפלה", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },

    // קטגוריה 7: קללות ובזיונות (25 מילים) - Weight: 2.0-7.0
    .{ .word = "בזיון", .weight = 4.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "בזויים", .weight = 4.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "קללה", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "קללות", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "חרא", .weight = 6.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "זבל", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE }, // trash vs insult
    .{ .word = "מזדיין", .weight = 7.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "לעזאזל", .weight = 5.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "ארור", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "מקולל", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "חארב", .weight = 6.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "גרוע", .weight = 1.0, .category = .HIGHLY_AMBIGUOUS }, // bad quality
    .{ .word = "נתעב", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "מגעיל", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "שפל", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "נבזה", .weight = 4.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "זלזול", .weight = 2.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "ביזיון", .weight = 4.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "בוז", .weight = 2.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "זלזל", .weight = 2.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "העליב", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "עלבון", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "חרפה", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "בושה", .weight = 2.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "מביש", .weight = 2.0, .category = .AMBIGUOUS_SENSITIVE },

    // קטגוריה 8: תרמית והונאה (15 מילים) - Weight: 3.0-8.0
    .{ .word = "הונאה", .weight = 4.0, .category = .AMBIGUOUS_SENSITIVE }, // fraud news
    .{ .word = "תרמית", .weight = 5.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "רמאות", .weight = 5.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "רמאי", .weight = 5.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "רמאים", .weight = 5.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "פירמידה", .weight = 7.0, .category = .CLEAR_SENSITIVE }, // pyramid scheme
    .{ .word = "מלטי", .weight = 6.0, .category = .CLEAR_SENSITIVE }, // MLM
    .{ .word = "משולב רמה", .weight = 8.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "פונזי", .weight = 8.0, .category = .VERY_CLEAR_SENSITIVE },
    .{ .word = "הטעיה", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "זיוף", .weight = 5.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "מזויף", .weight = 5.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "גניבה", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "גנב", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "גנבים", .weight = 3.0, .category = .AMBIGUOUS_SENSITIVE },

    // קטגוריה 9: פריצה והאקינג (10 מילים) - Weight: 3.0-7.0
    .{ .word = "פריצה", .weight = 4.0, .category = .AMBIGUOUS_SENSITIVE }, // hacking/security
    .{ .word = "האקינג", .weight = 5.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "האקר", .weight = 4.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "האקרים", .weight = 4.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "קרקינג", .weight = 6.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "קראקר", .weight = 6.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "פירוץ", .weight = 4.0, .category = .AMBIGUOUS_SENSITIVE },
    .{ .word = "פיראטי", .weight = 5.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "פיראטיות", .weight = 5.0, .category = .CLEAR_SENSITIVE },
    .{ .word = "העתק פיראטי", .weight = 7.0, .category = .CLEAR_SENSITIVE },
};

// ============================================================================
// KEYWORD CATEGORY (for weighted scoring)
// ============================================================================

const KeywordCategory = enum {
    VERY_CLEAR_BUSINESS, // 5.0 weight - חד-משמעי עסקי
    CLEAR_BUSINESS, // 2.0-4.0 weight
    AMBIGUOUS_BUSINESS, // 1.0 weight - תלוי הקשר

    VERY_CLEAR_SENSITIVE, // 10.0 weight - חד-משמעי רגיש
    CLEAR_SENSITIVE, // 5.0-8.0 weight
    AMBIGUOUS_SENSITIVE, // 1.0-3.0 weight
    HIGHLY_AMBIGUOUS, // 0.1-0.5 weight - מאוד דו-משמעי
};

const WeightedKeyword = struct {
    word: []const u8,
    weight: f32,
    category: KeywordCategory,
};

// ============================================================================
// HEBREW INFLECTIONS (תחיליות)
// ============================================================================

const HEBREW_PREFIXES = [_][]const u8{
    "ה", // ה' הידיעה
    "ב", // ב' מקום
    "ל", // ל' כיוון
    "מ", // מ' מקום
    "כ", // כ' דמיון
    "ש", // ש' קשר
    "ו", // ו' החיבור
};

const HEBREW_DOUBLE_PREFIXES = [_][]const u8{
    "וב", "וה", "ול", "ומ", "וכ", "וש",
    "שב", "של", "שמ", "מה", "בה", "כש",
};

// ... (continuing in next part due to length)
