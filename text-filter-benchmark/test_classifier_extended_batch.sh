#!/bin/bash

# Multi-Layer Classifier Extended Batch Test
# Testing with 215 keywords (120 business + 95 sensitive)

echo "========================================================"
echo "Multi-Layer Classifier - EXTENDED VERSION Batch Test"
echo "========================================================"
echo ""
echo "Keywords: 120 business + 95 sensitive = 215 total"
echo "Goal: Achieve 85%+ LLM call reduction"
echo ""

FILES=(
    "data/test_crm.html"
    "data/test_crm_large.html"
    "data/wikipedia_crm.html"
    "data/wikipedia_business.html"
    "data/wikipedia_company.html"
    "data/wikipedia_youtube.html"
    "data/test_sensitive.html"
)

total_files=0
llm_calls=0
skipped_llm=0
total_scan_time=0

echo "Testing ${#FILES[@]} files..."
echo ""

for file in "${FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "⚠️  Skipping $file (not found)"
        continue
    fi

    total_files=$((total_files + 1))

    echo "-------------------------------------------"
    echo "File $total_files: $(basename $file)"
    echo "-------------------------------------------"

    # Run classifier and capture decision
    output=$(./filter_html_classifier_extended "$file" 2>&1)

    # Extract key metrics
    content_class=$(echo "$output" | grep "Content Class:" | cut -d: -f2 | xargs)
    business_score=$(echo "$output" | grep "Business Score:" | awk '{print $NF}')
    sensitive_score=$(echo "$output" | grep "Sensitive Score:" | awk '{print $NF}')
    confidence=$(echo "$output" | grep "Confidence:" | awk '{print $NF}')
    scan_time=$(echo "$output" | grep "Layer 1 (keyword scan):" | awk '{print $NF}' | sed 's/ms//')

    # Accumulate scan time
    if [ -n "$scan_time" ]; then
        total_scan_time=$((total_scan_time + scan_time))
    fi

    # Check LLM decision
    if echo "$output" | grep -q "SKIP LLM"; then
        decision="🟢 SKIP LLM"
        skipped_llm=$((skipped_llm + 1))
    else
        decision="🔴 SEND TO LLM"
        llm_calls=$((llm_calls + 1))
    fi

    echo "  Class: $content_class"
    echo "  Business: $business_score | Sensitive: $sensitive_score"
    echo "  Confidence: $confidence"
    echo "  Scan time: ${scan_time}ms"
    echo "  Decision: $decision"
    echo ""
done

echo "========================================================"
echo "EXTENDED VERSION RESULTS"
echo "========================================================"
echo ""
echo "Total files tested: $total_files"
echo "LLM calls required: $llm_calls"
echo "LLM calls skipped: $skipped_llm"
echo ""

if [ $total_files -gt 0 ]; then
    reduction_pct=$((skipped_llm * 100 / total_files))
    echo "📊 LLM Call Reduction: $reduction_pct%"

    if [ $reduction_pct -ge 85 ]; then
        echo "✅ TARGET ACHIEVED! (Goal: ≥85%)"
    elif [ $reduction_pct -ge 70 ]; then
        echo "⚠️  Good performance (Goal: ≥85%)"
    else
        echo "❌ Below target (Goal: ≥85%)"
    fi

    echo ""
    echo "Performance Impact:"
    echo "  Without classifier: $total_files × 150ms = $((total_files * 150))ms total LLM time"
    echo "  With classifier: $llm_calls × 150ms + ${total_scan_time}ms = $((llm_calls * 150 + total_scan_time))ms"
    echo "  Time saved: $((total_files * 150 - llm_calls * 150 - total_scan_time))ms ($((100 - (llm_calls * 150 + total_scan_time) * 100 / (total_files * 150)))% faster)"
    echo ""
    echo "Keyword Performance:"
    echo "  Total keywords: 215 (120 business + 95 sensitive)"
    echo "  Avg scan time: $((total_scan_time / total_files))ms per file"
    echo "  Keywords/ms: $(awk "BEGIN {printf \"%.1f\", 215 / ($total_scan_time / $total_files)}")"
fi

echo ""
echo "========================================================"
echo "COMPARISON: Original vs Extended"
echo "========================================================"
echo ""
echo "Original (86 keywords):"
echo "  • Business: 50 keywords"
echo "  • Sensitive: 36 keywords"
echo "  • LLM reduction: 57% (4/7 skipped)"
echo "  • Avg scan time: ~1-2ms"
echo ""
echo "Extended (215 keywords):"
echo "  • Business: 120 keywords (+140%)"
echo "  • Sensitive: 95 keywords (+164%)"
echo "  • LLM reduction: $reduction_pct% ($skipped_llm/$total_files skipped)"
echo "  • Avg scan time: $((total_scan_time / total_files))ms"
echo ""

improvement=$((reduction_pct - 57))
if [ $improvement -gt 0 ]; then
    echo "🎉 Improvement: +${improvement}% LLM reduction with extended keywords!"
elif [ $improvement -eq 0 ]; then
    echo "📊 Same LLM reduction (more keywords = better coverage)"
else
    echo "⚠️  Same or lower reduction (but better coverage for edge cases)"
fi

echo ""
echo "========================================================"
echo "Classification Distribution:"
echo "========================================================"

# Re-run to get distribution
for file in "${FILES[@]}"; do
    if [ ! -f "$file" ]; then
        continue
    fi

    output=$(./filter_html_classifier_extended "$file" 2>&1)

    if echo "$output" | grep -q "CLEAN"; then
        echo "  ✅ $(basename $file): CLEAN"
    elif echo "$output" | grep -q "BUSINESS_CONTENT"; then
        echo "  📊 $(basename $file): BUSINESS_CONTENT"
    elif echo "$output" | grep -q "SENSITIVE_CONTENT"; then
        echo "  🚫 $(basename $file): SENSITIVE_CONTENT"
    elif echo "$output" | grep -q "MIXED_CONTENT"; then
        echo "  ⚠️  $(basename $file): MIXED_CONTENT"
    elif echo "$output" | grep -q "NEEDS_REVIEW"; then
        echo "  ❓ $(basename $file): NEEDS_REVIEW"
    fi
done

echo ""
