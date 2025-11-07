#!/bin/bash

echo "=========================================="
echo "בדיקת כל קבצי ה-HTML בפרויקט"
echo "=========================================="
echo

# Array of all HTML files
declare -a files=(
    "data/test_crm.html"
    "data/wikipedia_crm.html"
    "data/wikipedia_business.html"
    "data/wikipedia_company.html"
    "/home/user/RustCRM/hebrew-content-filter/tests/test_patterns.html"
    "/home/user/RustCRM/hebrew-content-filter/tests/test_clean.html"
)

echo "קובץ                    | גודל    | טקסט   | זמן  | מילות מפתח | התאמות"
echo "------------------------|---------|--------|------|-------------|--------"

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        output=$(./optimized/zig/filter_html_keywords_optimized "$file" 2>&1)
        
        size=$(echo "$output" | grep "HTML size:" | awk '{print $3}')
        text=$(echo "$output" | grep "Extracted text:" | awk '{print $3}')
        time=$(echo "$output" | grep "Total time:" | awk '{print $3}')
        keywords=$(echo "$output" | grep "Unique keywords found:" | awk '{print $4}')
        matches=$(echo "$output" | grep "Total keyword occurrences:" | awk '{print $4}')
        
        printf "%-23s | %7s | %6s | %4s | %11s | %6s\n" \
            "$filename" "$size" "$text" "$time" "$keywords" "$matches"
    fi
done

echo
echo "✓ בדיקה הושלמה!"
echo
echo "סה\"כ: 6 קבצי HTML נבדקו"
