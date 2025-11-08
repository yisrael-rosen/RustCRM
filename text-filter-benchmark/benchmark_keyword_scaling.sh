#!/bin/bash

# Benchmark: How does scan time scale with keyword count?
# Tests: 50, 86, 120, 215, 400, 800, 1600 keywords

echo "========================================================"
echo "Keyword Scaling Benchmark"
echo "========================================================"
echo ""
echo "Question: What happens to scan time as keyword list grows?"
echo "Test: Measure scan time with different keyword counts"
echo ""

# Test file
TEST_FILE="data/wikipedia_company.html"
TEXT_SIZE=$(stat -f%z "$TEST_FILE" 2>/dev/null || stat -c%s "$TEST_FILE" 2>/dev/null)

echo "Test file: $TEST_FILE"
echo "Size: $TEXT_SIZE bytes"
echo ""

# Get results from existing classifiers
echo "========================================================"
echo "Current Results:"
echo "========================================================"
echo ""

# Original (86 keywords)
echo "Testing with 86 keywords (original)..."
result=$(./zig/filter_html_classifier "$TEST_FILE" 2>&1)
scan_time_86=$(echo "$result" | grep "Layer 1 (keyword scan):" | awk '{print $NF}' | sed 's/ms//')
echo "  Keywords: 86"
echo "  Scan time: ${scan_time_86}ms"
echo "  Keywords/ms: $(awk "BEGIN {printf \"%.1f\", 86 / $scan_time_86}")"
echo ""

# Extended (215 keywords)
echo "Testing with 215 keywords (extended)..."
result=$(./filter_html_classifier_extended "$TEST_FILE" 2>&1)
scan_time_215=$(echo "$result" | grep "Layer 1 (keyword scan):" | awk '{print $NF}' | sed 's/ms//')
echo "  Keywords: 215"
echo "  Scan time: ${scan_time_215}ms"
echo "  Keywords/ms: $(awk "BEGIN {printf \"%.1f\", 215 / $scan_time_215}")"
echo ""

echo "========================================================"
echo "Scaling Analysis:"
echo "========================================================"
echo ""

# Calculate scaling factor
scaling_factor=$(awk "BEGIN {printf \"%.2f\", $scan_time_215 / $scan_time_86}")
keyword_ratio=$(awk "BEGIN {printf \"%.2f\", 215 / 86}")

echo "Keyword increase: 86 → 215 (×${keyword_ratio})"
echo "Time increase: ${scan_time_86}ms → ${scan_time_215}ms (×${scaling_factor})"
echo ""

if (( $(echo "$scaling_factor < $keyword_ratio" | bc -l) )); then
    echo "✅ SUB-LINEAR scaling (good!)"
    echo "   Time grew slower than keywords"
else
    echo "⚠️  LINEAR scaling"
    echo "   Time grew proportionally to keywords"
fi

echo ""
echo "========================================================"
echo "Projections for Larger Lists:"
echo "========================================================"
echo ""

# Project for different sizes
project_time() {
    keywords=$1
    # Assume linear scaling (conservative)
    projected=$(awk "BEGIN {printf \"%.0f\", $scan_time_215 * $keywords / 215}")
    echo "$projected"
}

echo "Based on current scaling (linear assumption):"
echo ""
echo "  400 keywords  → $(project_time 400)ms per file"
echo "  800 keywords  → $(project_time 800)ms per file"
echo "  1,600 keywords → $(project_time 1600)ms per file"
echo "  2,400 keywords → $(project_time 2400)ms per file (with inflections)"
echo ""

echo "========================================================"
echo "Hebrew Inflections Impact:"
echo "========================================================"
echo ""

echo "Hebrew prefixes: ה, ב, ל, מ, כ, ש (6 common)"
echo "Example: 'לקוח' → לקוח, הלקוח, בלקוח, ללקוח, מלקוח, כלקוח, שלקוח"
echo ""
echo "If we add inflections to 400 base words:"
echo "  400 base words × 7 forms (base + 6 prefixes) = 2,800 keywords"
echo ""
echo "Projected scan time: $(project_time 2800)ms per file"
echo ""

# Calculate if it's still acceptable
acceptable_time=50  # ms
current_400=$(project_time 400)
current_2800=$(project_time 2800)

echo "========================================================"
echo "Real-time Performance Check:"
echo "========================================================"
echo ""
echo "Target: <50ms per page (for real-time processing)"
echo ""

if [ "$current_400" -lt "$acceptable_time" ]; then
    echo "✅ 400 keywords: ${current_400}ms - ACCEPTABLE"
else
    echo "⚠️  400 keywords: ${current_400}ms - TOO SLOW"
fi

if [ "$current_2800" -lt "$acceptable_time" ]; then
    echo "✅ 2,800 keywords: ${current_2800}ms - ACCEPTABLE"
else
    echo "⚠️  2,800 keywords: ${current_2800}ms - TOO SLOW"
fi

echo ""
echo "========================================================"
echo "Optimization Strategies if TOO SLOW:"
echo "========================================================"
echo ""

echo "1. Hash Table / Trie:"
echo "   - O(text_length) instead of O(text_length × keywords)"
echo "   - 100-1000x faster for large keyword lists"
echo "   - Trade-off: more complex code"
echo ""

echo "2. Suffix Matching (for inflections):"
echo "   - Store base word + check if text ends with it"
echo "   - Example: check 'לקוח' matches 'הלקוח', 'בלקוח'"
echo "   - Reduces 2,800 → 400 keywords"
echo ""

echo "3. Regex-based (batch patterns):"
echo "   - Single regex: (ה|ב|ל|מ|כ|ש)?לקוח"
echo "   - Faster than 7 separate searches"
echo "   - Trade-off: less precise"
echo ""

echo "4. Parallel Processing:"
echo "   - Already doing this for large files"
echo "   - Can split keyword list across workers"
echo ""

echo "========================================================"
echo "Recommendation:"
echo "========================================================"
echo ""

if [ "$current_2800" -lt 100 ]; then
    echo "✅ Current approach is FINE even with 2,800 keywords!"
    echo "   Projected time: ${current_2800}ms"
    echo "   Just add inflections, no optimization needed"
elif [ "$current_400" -lt "$acceptable_time" ]; then
    echo "⚠️  Use suffix matching instead of full inflections"
    echo "   Keep 400 base words, match with prefixes in code"
    echo "   This keeps scan time at ${current_400}ms"
else
    echo "🔴 Need optimization strategy (hash table or trie)"
    echo "   Current approach won't scale to 400+ keywords"
fi

echo ""
