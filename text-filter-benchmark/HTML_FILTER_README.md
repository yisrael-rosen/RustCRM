# HTML Content Filter - Zig Implementation

מנוע סינון תוכן HTML עם 50 מילות מפתח בעברית

## תיאור

מנוע מתקדם לסינון תוכן HTML המחלץ טקסט מקבצי HTML ומזהה 50 מילות מפתח בעברית. המערכת מתעלמת מתגי `<script>` ו-`<style>` ומתמקדת רק בתוכן הטקסטואלי הגלוי.

## תכונות עיקריות

✅ **HTML Parser בנוי בעצמו** - ללא תלות בספריות חיצוניות
✅ **הסרת תגים אוטומטית** - מחלץ רק טקסט גלוי
✅ **סינון Scripts & Styles** - מתעלם מקוד JavaScript ו-CSS
✅ **50 מילות מפתח בעברית** - מחולקות ל-5 קטגוריות
✅ **גרסה מקבילית** - עיבוד מהיר עם ניצול מלא של המעבד
✅ **תמיכה ב-UTF-8** - תמיכה מלאה בטקסט עברי
✅ **סטטיסטיקות מפורטות** - דוח מלא על כל מילת מפתח

## מילות המפתח (50 מילים)

המערכת מחפשת 50 מילות מפתח המחולקות ל-5 קטגוריות:

### קטגוריה 1: תקשורת ומידע
שלום, הודעה, מידע, עדכון, התראה, דיווח, פרטים, תיאור, הסבר, תוכן

### קטגוריה 2: פעולות עסקיות
רכישה, מכירה, עסקה, הזמנה, תשלום, חשבונית, הצעה, חוזה, הסכם, דיל

### קטגוריה 3: סטטוס ומצב
מאושר, ממתין, בטיפול, הושלם, בוטל, נדחה, פעיל, סגור, פתוח, חדש

### קטגוריה 4: לקוחות וקשרים
לקוח, חברה, איש קשר, ספק, שותף, צוות, מנהל, משתמש, משקיע, יועץ

### קטגוריה 5: משימות ופעילות
משימה, פגישה, שיחה, אימייל, פעילות, מעקב, תזכורת, יומן, לוח, תכנון

## התקנה ובנייה

```bash
# הרצת סקריפט הבנייה
./build_keywords.sh
```

הסקריפט יבנה 4 גרסאות:
1. מסנן טקסט בסיסי
2. מסנן טקסט מקבילי
3. **מסנן HTML בסיסי** ⭐
4. **מסנן HTML מקבילי** ⭐

## שימוש

### גרסה בסיסית
```bash
./zig/filter_html_keywords <file.html>
```

### גרסה מקבילית (מומלץ)
```bash
./optimized/zig/filter_html_keywords_optimized <file.html>
```

## דוגמאות

### 1. סינון קובץ HTML בודד

```bash
./zig/filter_html_keywords data/test_crm.html
```

**פלט:**
```
=== Zig HTML Keyword Filter ===
HTML file: data/test_crm.html
HTML size: 5028 bytes
Extracted text: 2146 bytes
Total keywords: 50
Time elapsed: 2ms

--- Keyword Matches ---
  לקוח: 6 matches
  חדש: 12 matches
  פעיל: 6 matches
  ...

--- Summary ---
Unique keywords found: 45/50
Total keyword occurrences: 86

✓ Content filtering detected 86 keyword matches
```

### 2. סינון קובץ גדול (גרסה מקבילית)

```bash
./optimized/zig/filter_html_keywords_optimized data/test_crm_large.html
```

**פלט:**
```
=== Zig Optimized HTML Keyword Filter ===
HTML file: data/test_crm_large.html
HTML size: 502800 bytes
Extracted text: 214600 bytes
HTML parsing time: 3ms
Workers used: 8
Total time: 12ms

Performance: 39.96 MB/s
```

## ביצועים

### קובץ בודד (5KB)
| גרסה | זמן | throughput |
|------|-----|------------|
| בסיסית | 2ms | ~2.5 MB/s |
| מקבילית | 1ms | ~5 MB/s |

### קובץ גדול (500KB)
| גרסה | זמן | throughput |
|------|-----|------------|
| בסיסית | 14ms | ~35 MB/s |
| מקבילית | 12ms | ~40 MB/s |

**הערה:** הגרסה המקבילית מציגה שיפור משמעותי בקבצים גדולים יותר (>1MB).

## אדריכלות

### 1. HTML Parser

```zig
pub const HtmlParser = struct {
    allocator: std.mem.Allocator,

    // מחלץ טקסט מ-HTML
    pub fn extractText(html: []const u8) ![]u8

    // מחלץ טקסט מתג ספציפי
    pub fn extractFromTag(html: []const u8, tag_name: []const u8) ![]u8
};
```

**תכונות:**
- הסרת כל תגי HTML
- סינון אוטומטי של `<script>` ו-`<style>`
- שמירה על רווחים בין מילים
- טיפול ב-UTF-8

### 2. Keyword Matcher

מנוע חיפוש המזהה את כל 50 מילות המפתח בטקסט המחולץ:

```zig
// חיפוש כל המופעים של כל מילת מפתח
for (KEYWORDS, 0..) |keyword, i| {
    var count: usize = 0;
    while (std.mem.indexOf(u8, text, keyword)) |pos| {
        count += 1;
        // המשך חיפוש...
    }
    keyword_matches[i] = count;
}
```

### 3. Parallel Processing (גרסה מקבילית)

```zig
// חלוקת הטקסט ל-N chunks
const cpu_count = try std.Thread.getCpuCount();
const num_workers = @min(cpu_count, 8);

// עיבוד מקבילי
for (chunks) |chunk| {
    thread = try std.Thread.spawn(processChunk, chunk);
}

// איחוד תוצאות
for (results) |result| {
    aggregate(result);
}
```

## קבצי בדיקה

### test_crm.html

קובץ HTML לדוגמא של מערכת CRM עם:
- דשבורד ניהול לקוחות
- עסקאות ומשימות
- התראות ועדכונים
- סטטיסטיקות
- תגי script (לבדיקת סינון)

גודל: ~5KB
תוכן: 45 מילות מפתח שונות

## מקרי שימוש

### 1. סינון תוכן CRM
זיהוי אוטומטי של מסמכי CRM ומיון לפי תוכן:

```bash
for file in crm_exports/*.html; do
    ./zig/filter_html_keywords "$file"
done
```

### 2. ניטור אתרים
בדיקת תוכן אתרים לאיתור מידע עסקי:

```bash
wget https://example.com -O page.html
./zig/filter_html_keywords page.html
```

### 3. ניתוח דוחות
עיבוד דוחות HTML ומיצוי נתונים:

```bash
./optimized/zig/filter_html_keywords_optimized quarterly_report.html
```

### 4. סינון אימיילים
ניתוח אימיילים בפורמט HTML:

```bash
cat email.html | ./zig/filter_html_keywords /dev/stdin
```

## השוואה לשפות אחרות

| תכונה | Zig | Python (BeautifulSoup) | JavaScript (Cheerio) |
|-------|-----|------------------------|----------------------|
| מהירות | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ |
| זיכרון | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| תלות | אפס ✅ | רבות ❌ | רבות ❌ |
| Binary גודל | קטן | גדול | בינוני |
| Deploy | פשוט ✅ | מורכב | בינוני |

## פרטים טכניים

### אופטימיזציות

1. **Zero-Copy Parsing**: עיבוד ישיר מהזיכרון ללא העתקות
2. **Single-Pass Parsing**: מעבר אחד על ה-HTML
3. **Efficient String Search**: שימוש ב-`std.mem.indexOf` המהיר
4. **Parallel Processing**: ניצול מלא של כל ליבות המעבד
5. **Release Optimization**: קומפילציה עם `-O ReleaseFast`

### טיפול בקצה מקרים

- **HTML לא תקין**: הparser סובלני ועובד גם עם HTML לא מושלם
- **קבצים ריקים**: החזרת תוצאה ריקה
- **טקסט ללא HTML**: עיבוד כטקסט רגיל
- **UTF-8 encoding**: תמיכה מלאה בתווים עבריים

### מגבלות ידועות

1. **Nested Scripts**: תגי script מקוננים עלולים לגרום לבעיות
2. **Malformed HTML**: HTML שגוי מאוד עלול להתפרש לא נכון
3. **Memory**: קבצים גדולים מאוד (>100MB) דורשים זיכרון רב

## פיתוחים עתידיים

- [ ] תמיכה ב-HTML entities (`&nbsp;`, `&copy;`)
- [ ] חילוץ מטא-דאטה (title, meta tags)
- [ ] זיהוי מבנה HTML (headers, paragraphs)
- [ ] תמיכה ב-streaming (קבצים ענקיים)
- [ ] Export ל-JSON/CSV
- [ ] Fuzzy matching למילות מפתח
- [ ] אינטגרציה עם המנוע המורפולוגי העברי

## רישיון

MIT License - ראה LICENSE בשורש הפרויקט

## תודות

- מבוסס על מנוע סינון הטקסט המקורי
- השראה מ-hebrew-content-filter (Rust implementation)
- מימוש HTML parser פשוט ויעיל בהשראת scraper.rs

---

**נוצר עם ❤️ בשביל RustCRM**
