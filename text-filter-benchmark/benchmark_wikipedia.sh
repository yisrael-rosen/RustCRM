#!/bin/bash

echo "=========================================="
echo "בדיקת מנוע סינון HTML על דפי ויקיפדיה"
echo "=========================================="
echo

# Test all Wikipedia files
for file in data/wikipedia_*.html; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        echo "מעבד: $filename"
        ./optimized/zig/filter_html_keywords_optimized "$file" 2>&1 | grep -E "(HTML size|Extracted text|Total time|Unique keywords|Total keyword|Performance)" | sed 's/^/  /'
        echo
    fi
done

echo "=========================================="
echo "סיכום כללי"
echo "=========================================="
echo

# Summary table
echo "קובץ                     | גודל    | טקסט   | זמן  | מילות מפתח | התאמות | throughput"
echo "-------------------------|---------|--------|------|-------------|--------|------------"

for file in data/wikipedia_*.html; do
    if [ -f "$file" ]; then
        filename=$(basename "$file" .html | sed 's/wikipedia_//')
        output=$(./optimized/zig/filter_html_keywords_optimized "$file" 2>&1)
        
        size=$(echo "$output" | grep "HTML size:" | awk '{print $3}')
        text=$(echo "$output" | grep "Extracted text:" | awk '{print $3}')
        time=$(echo "$output" | grep "Total time:" | awk '{print $3}')
        keywords=$(echo "$output" | grep "Unique keywords found:" | awk '{print $4}')
        matches=$(echo "$output" | grep "Total keyword occurrences:" | awk '{print $4}')
        perf=$(echo "$output" | grep "Performance:" | awk '{print $2}')
        
        printf "%-24s | %7s | %6s | %4s | %11s | %6s | %s\n" \
            "$filename" "$size" "$text" "$time" "$keywords" "$matches" "$perf"
    fi
done

echo
echo "✓ בדיקה הושלמה בהצלחה!"
