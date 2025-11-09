#!/bin/bash

# Benchmark: Raw Text vs HTML Parsing
# Compares performance and accuracy of blind text scan vs HTML parsing

echo "=========================================================="
echo "RAW TEXT vs HTML PARSING - Performance Comparison"
echo "=========================================================="
echo ""
echo "Testing strategy:"
echo "  1. RAW TEXT: Scan entire file blindly (including tags)"
echo "  2. HTML PARSING: Extract text, then scan (current approach)"
echo ""
echo "Expected:"
echo "  - Raw: FASTER (no parsing overhead)"
echo "  - HTML: More ACCURATE (no false positives from tags)"
echo ""

FILES=(
    "data/test_crm.html"
    "data/wikipedia_crm.html"
    "data/wikipedia_business.html"
    "data/wikipedia_company.html"
    "data/wikipedia_youtube.html"
    "data/wikipedia_homophobia.html"
)

echo "Testing ${#FILES[@]} files..."
echo ""

total_raw_time=0
total_html_time=0
total_files=0

raw_skip=0
html_skip=0

for file in "${FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "⚠️  Skipping $file (not found)"
        continue
    fi

    total_files=$((total_files + 1))
    filename=$(basename "$file")
    filesize=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)

    echo "=========================================="
    echo "File $total_files: $filename"
    echo "Size: $(numfmt --to=iec-i --suffix=B $filesize 2>/dev/null || echo \"$filesize bytes\")"
    echo "=========================================="

    # Test RAW TEXT (no HTML parsing)
    echo "Testing RAW TEXT (no parsing)..."
    raw_output=$(./raw_text_classifier "$file" 2>&1)

    raw_business=$(echo "$raw_output" | grep "Business keywords:" | awk '{print $3}')
    raw_sensitive=$(echo "$raw_output" | grep "Sensitive keywords:" | awk '{print $3}')
    raw_scan_time=$(echo "$raw_output" | grep "Scan time:" | awk '{print $3}' | sed 's/ms//')
    raw_decision=$(echo "$raw_output" | grep "Decision:" | awk '{print $2, $3}')

    if echo "$raw_decision" | grep -q "SKIP"; then
        raw_skip=$((raw_skip + 1))
        raw_result="🟢 SKIP"
    else
        raw_result="🔴 SEND"
    fi

    total_raw_time=$((total_raw_time + raw_scan_time))

    # Test HTML PARSING (current approach)
    echo "Testing HTML PARSING (extract text first)..."
    html_output=$(./filter_html_classifier_extended "$file" 2>&1)

    html_business=$(echo "$html_output" | grep "Business Score:" | awk '{print $NF}')
    html_sensitive=$(echo "$html_output" | grep "Sensitive Score:" | awk '{print $NF}')
    html_scan_time=$(echo "$html_output" | grep "Layer 1 (keyword scan):" | awk '{print $NF}' | sed 's/ms//')
    html_decision=$(echo "$html_output" | grep -A1 "Layer 3:" | grep "Decision:" | head -1)

    if echo "$html_decision" | grep -q "SKIP"; then
        html_skip=$((html_skip + 1))
        html_result="🟢 SKIP"
    else
        html_result="🔴 SEND"
    fi

    total_html_time=$((total_html_time + html_scan_time))

    # Display comparison
    echo ""
    echo "RAW TEXT (no parsing):"
    echo "  Business: $raw_business | Sensitive: $raw_sensitive"
    echo "  Scan time: ${raw_scan_time}ms"
    echo "  Decision: $raw_result"
    echo ""
    echo "HTML PARSING (extract text):"
    echo "  Business: $html_business | Sensitive: $html_sensitive"
    echo "  Scan time: ${html_scan_time}ms"
    echo "  Decision: $html_result"
    echo ""

    # Calculate difference
    if [ -n "$raw_scan_time" ] && [ -n "$html_scan_time" ] && [ "$html_scan_time" -gt 0 ]; then
        speedup=$(awk "BEGIN {printf \"%.1f\", $html_scan_time / $raw_scan_time}")
        echo "⚡ Raw is ${speedup}x faster!"
    fi

    # Check if results differ
    if [ "$raw_result" != "$html_result" ]; then
        echo "⚠️  DIFFERENT DECISIONS!"
        echo "   Raw: $raw_result vs HTML: $html_result"
    else
        echo "✅ Same decision"
    fi

    # Check for false positives
    business_diff=$((raw_business - html_business))
    sensitive_diff=$((raw_sensitive - html_sensitive))

    if [ $business_diff -gt 0 ] || [ $sensitive_diff -gt 0 ]; then
        echo "📊 Extra matches in raw (likely from HTML tags):"
        [ $business_diff -gt 0 ] && echo "   Business: +$business_diff"
        [ $sensitive_diff -gt 0 ] && echo "   Sensitive: +$sensitive_diff"
    fi

    echo ""
done

echo "=========================================================="
echo "SUMMARY"
echo "=========================================================="
echo ""
echo "Total files tested: $total_files"
echo ""

# Performance comparison
if [ $total_files -gt 0 ]; then
    avg_raw=$((total_raw_time / total_files))
    avg_html=$((total_html_time / total_files))

    echo "Performance:"
    echo "  Raw text scan: ${total_raw_time}ms total, ${avg_raw}ms avg"
    echo "  HTML parsing:  ${total_html_time}ms total, ${avg_html}ms avg"

    if [ $total_raw_time -lt $total_html_time ]; then
        speedup=$(awk "BEGIN {printf \"%.1f\", $total_html_time / $total_raw_time}")
        improvement_pct=$(awk "BEGIN {printf \"%.0f\", ($total_html_time - $total_raw_time) * 100 / $total_html_time}")
        echo ""
        echo "⚡ Raw text is ${speedup}x FASTER (${improvement_pct}% improvement!)"
    else
        echo ""
        echo "⚠️  HTML parsing is actually faster (surprising!)"
    fi
fi

echo ""

# Accuracy comparison
echo "LLM Reduction:"
echo "  Raw text:     $raw_skip/$total_files skipped ($((raw_skip * 100 / total_files))%)"
echo "  HTML parsing: $html_skip/$total_files skipped ($((html_skip * 100 / total_files))%)"
echo ""

if [ $raw_skip -eq $html_skip ]; then
    echo "✅ Same LLM reduction!"
elif [ $raw_skip -gt $html_skip ]; then
    diff=$((raw_skip - html_skip))
    echo "⚠️  Raw skips MORE files (+$diff)"
    echo "   (Might have false positives from HTML tags)"
elif [ $html_skip -gt $raw_skip ]; then
    diff=$((html_skip - raw_skip))
    echo "⚠️  HTML skips MORE files (+$diff)"
    echo "   (Better at filtering out noise)"
fi

echo ""
echo "=========================================================="
echo "Recommendation:"
echo "=========================================================="
echo ""

if [ $total_raw_time -lt $total_html_time ]; then
    speedup=$(awk "BEGIN {printf \"%.1f\", $total_html_time / $total_raw_time}")

    echo "Raw text is ${speedup}x faster!"
    echo ""

    if [ $raw_skip -eq $html_skip ]; then
        echo "✅ USE RAW TEXT - Same accuracy, much faster!"
    elif [ $raw_skip -gt $html_skip ]; then
        echo "⚠️  RAW TEXT has MORE skips (possible false positives)"
        echo "   Trade-off: Speed vs Accuracy"
        echo "   - For speed: Use raw text"
        echo "   - For accuracy: Use HTML parsing"
    else
        echo "✅ USE HTML PARSING - Better accuracy"
    fi
else
    echo "HTML parsing is not slower - keep using it!"
fi

echo ""
