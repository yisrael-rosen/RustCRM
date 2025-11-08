#!/bin/bash

# Multi-Layer Classifier Batch Test
# Demonstrates LLM call reduction across multiple files

echo "================================================"
echo "Multi-Layer Content Classifier - Batch Test"
echo "================================================"
echo ""
echo "Testing classifier on various HTML files to measure"
echo "LLM call reduction (Target: 85% reduction)"
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
    output=$(./filter_html_classifier "$file" 2>&1)

    # Extract key metrics
    content_class=$(echo "$output" | grep "Content Class:" | cut -d: -f2 | xargs)
    business_score=$(echo "$output" | grep "Business Score:" | awk '{print $NF}')
    sensitive_score=$(echo "$output" | grep "Sensitive Score:" | awk '{print $NF}')
    confidence=$(echo "$output" | grep "Confidence:" | awk '{print $NF}')

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
    echo "  Decision: $decision"
    echo ""
done

echo "================================================"
echo "RESULTS SUMMARY"
echo "================================================"
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
    echo "  With classifier: $llm_calls × 150ms + $total_files × 1ms = $((llm_calls * 150 + total_files))ms"
    echo "  Time saved: $((total_files * 150 - llm_calls * 150 - total_files))ms ($((100 - (llm_calls * 150 + total_files) * 100 / (total_files * 150)))% faster)"
fi

echo ""
echo "================================================"
echo "Classification Distribution:"
echo "================================================"

# Re-run to get distribution
for file in "${FILES[@]}"; do
    if [ ! -f "$file" ]; then
        continue
    fi

    output=$(./filter_html_classifier "$file" 2>&1)

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
