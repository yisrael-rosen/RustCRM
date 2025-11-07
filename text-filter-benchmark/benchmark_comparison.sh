#!/bin/bash

set -e

DATA_FILE="data/testdata.txt"
PATTERN="ERROR"
RUNS=3

if [ ! -f "$DATA_FILE" ]; then
    echo "Error: Test data file not found: $DATA_FILE"
    exit 1
fi

echo "================================================================"
echo "            Side-by-Side Performance Comparison"
echo "            Original vs Optimized Implementations"
echo "================================================================"
echo "Data file: $DATA_FILE ($(du -h $DATA_FILE | cut -f1))"
echo "Search pattern: '$PATTERN'"
echo "Runs per implementation: $RUNS"
echo ""

# Function to extract and average times
run_comparison() {
    local lang=$1
    local original_cmd=$2
    local optimized_cmd=$3

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  $lang"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Run original
    echo -n "  Original:  "
    local orig_total=0
    for i in $(seq 1 $RUNS); do
        output=$($original_cmd "$DATA_FILE" "$PATTERN" 2>&1)
        time=$(echo "$output" | grep "Time elapsed" | awk '{print $3}' | sed 's/ms//')
        orig_total=$((orig_total + time))
        echo -n "$time "
    done
    local orig_avg=$((orig_total / RUNS))
    echo "→ Avg: ${orig_avg}ms"

    # Run optimized
    echo -n "  Optimized: "
    local opt_total=0
    for i in $(seq 1 $RUNS); do
        output=$($optimized_cmd "$DATA_FILE" "$PATTERN" 2>&1)
        time=$(echo "$output" | grep "Time elapsed" | awk '{print $3}' | sed 's/ms//')
        opt_total=$((opt_total + time))
        echo -n "$time "
    done
    local opt_avg=$((opt_total / RUNS))
    echo "→ Avg: ${opt_avg}ms"

    # Calculate improvement
    local diff=$((orig_avg - opt_avg))
    local percent=$((diff * 100 / orig_avg))

    if [ $opt_avg -lt $orig_avg ]; then
        echo "  📈 Improvement: ${percent}% faster (${diff}ms saved)"
    elif [ $opt_avg -gt $orig_avg ]; then
        percent=$((-percent))
        echo "  📉 Regression: ${percent}% slower (${diff}ms slower)"
    else
        echo "  ≈  No change"
    fi
    echo ""
}

# Run comparisons
run_comparison "Zig" "./zig/filter" "./optimized/zig/filter_optimized"
run_comparison "Rust" "./rust/target/release/text-filter" "./optimized/rust/target/release/text-filter-optimized"
run_comparison "Go" "./go/filter" "./optimized/go/filter_optimized"

echo "================================================================"
echo "                    Comparison Complete!"
echo "================================================================"
