#!/bin/bash

echo "=========================================="
echo "בדיקת דפי ויקיפדיה גדולים (1-2.5 MB)"
echo "=========================================="
echo

# Large Wikipedia files
declare -a files=(
    "data/wikipedia_iron_swords.html"
    "data/wikipedia_youtube.html"
)

echo "קובץ                     | גודל HTML | טקסט   | זמן  | מילות מפתח | התאמות | Throughput"
echo "-------------------------|-----------|--------|------|-------------|--------|------------"

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        filename=$(basename "$file" .html | sed 's/wikipedia_//')
        output=$(./optimized/zig/filter_html_keywords_optimized "$file" 2>&1)
        
        size=$(echo "$output" | grep "HTML size:" | awk '{print $3}')
        text=$(echo "$output" | grep "Extracted text:" | awk '{print $3}')
        time=$(echo "$output" | grep "Total time:" | awk '{print $3}')
        keywords=$(echo "$output" | grep "Unique keywords found:" | awk '{print $4}')
        matches=$(echo "$output" | grep "Total keyword occurrences:" | awk '{print $4}')
        perf=$(echo "$output" | grep "Performance:" | awk '{print $2}')
        
        # Convert bytes to MB for display
        size_mb=$(echo "scale=1; $size / 1048576" | bc)
        text_kb=$(echo "scale=0; $text / 1024" | bc)
        
        printf "%-24s | %8s MB | %5s KB | %4s | %11s | %6s | %s\n" \
            "$filename" "$size_mb" "$text_kb" "$time" "$keywords" "$matches" "$perf"
    fi
done

echo
echo "✓ בדיקה הושלמה!"
