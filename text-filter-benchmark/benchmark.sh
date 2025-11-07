#!/bin/bash

set -e

DATA_FILE="data/testdata.txt"
PATTERN="ERROR"
RUNS=5

if [ ! -f "$DATA_FILE" ]; then
    echo "Error: Test data file not found: $DATA_FILE"
    exit 1
fi

echo "================================"
echo "Text Filter Performance Benchmark"
echo "================================"
echo "Data file: $DATA_FILE"
echo "Search pattern: $PATTERN"
echo "Number of runs: $RUNS"
echo ""

# Function to run benchmark
run_benchmark() {
    local lang=$1
    local cmd=$2

    echo "Benchmarking $lang..."
    echo "---"

    local total_time=0

    for i in $(seq 1 $RUNS); do
        echo "Run $i/$RUNS:"
        output=$($cmd "$DATA_FILE" "$PATTERN")
        echo "$output"

        # Extract time from output
        time=$(echo "$output" | grep "Time elapsed" | awk '{print $3}' | sed 's/ms//')
        total_time=$((total_time + time))
        echo ""
    done

    local avg_time=$((total_time / RUNS))
    echo "Average time for $lang: ${avg_time}ms"
    echo ""
    echo "================================"
    echo ""
}

# Run benchmarks
run_benchmark "Zig" "./zig/filter"
run_benchmark "Rust" "./rust/target/release/text-filter"
run_benchmark "Go" "./go/filter"

echo ""
echo "Benchmark complete!"
