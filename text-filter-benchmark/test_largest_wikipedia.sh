#!/bin/bash

echo "=========================================="
echo "בדיקת הדף הגדול ביותר בויקיפדיה העברית"
echo "=========================================="
echo

echo "דף: הומופוביה ברחבי העולם"
echo "גודל מקורי (טקסט בלבד): 1,140,981 bytes"
echo "גודל HTML שהורד: $(ls -lh data/wikipedia_homophobia.html | awk '{print $5}')"
echo

./optimized/zig/filter_html_keywords_optimized data/wikipedia_homophobia.html

echo
echo "=========================================="
echo "השוואה לדפים הגדולים האחרים"
echo "=========================================="
echo

declare -a files=(
    "data/wikipedia_homophobia.html"
    "data/wikipedia_iron_swords.html"
    "data/wikipedia_youtube.html"
)

echo "דף                      | גודל    | זמן  | התאמות | Throughput"
echo "------------------------|---------|------|--------|------------"

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        filename=$(basename "$file" .html | sed 's/wikipedia_//')
        output=$(./optimized/zig/filter_html_keywords_optimized "$file" 2>&1)
        
        size=$(echo "$output" | grep "HTML size:" | awk '{print $3}')
        time=$(echo "$output" | grep "Total time:" | awk '{print $3}')
        matches=$(echo "$output" | grep "Total keyword occurrences:" | awk '{print $4}')
        perf=$(echo "$output" | grep "Performance:" | awk '{print $2}')
        
        size_mb=$(echo "scale=1; $size / 1048576" | bc)
        
        printf "%-23s | %6s MB | %4s | %6s | %s\n" \
            "$filename" "$size_mb" "$time" "$matches" "$perf"
    fi
done

echo
echo "✓ השלמנו את בדיקת כל הדפים הגדולים!"
