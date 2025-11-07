#!/bin/bash

# Benchmark script for Zig keyword filters (50 Hebrew keywords)

set -e

echo "=========================================="
echo "Zig Multi-Keyword Filter Benchmark"
echo "Testing with 50 Hebrew keywords"
echo "=========================================="
echo

# Check if test data exists
if [ ! -f "data/test_hebrew_large.txt" ]; then
    echo "Error: Test data not found!"
    echo "Please run: for i in {1..10000}; do cat data/test_hebrew.txt; done > data/test_hebrew_large.txt"
    exit 1
fi

FILE_SIZE=$(du -h data/test_hebrew_large.txt | cut -f1)
echo "Test file size: $FILE_SIZE"
echo

# Benchmark basic version
echo "==================================="
echo "1. Basic Zig Keyword Filter"
echo "==================================="
echo

RUNS=3
TOTAL_TIME=0

for i in $(seq 1 $RUNS); do
    echo "Run $i/$RUNS..."
    OUTPUT=$(./zig/filter_keywords data/test_hebrew_large.txt 2>&1)
    TIME=$(echo "$OUTPUT" | grep "Time elapsed:" | awk '{print $3}' | sed 's/ms//')
    TOTAL_TIME=$((TOTAL_TIME + TIME))
    echo "  Time: ${TIME}ms"
done

BASIC_AVG=$((TOTAL_TIME / RUNS))
echo
echo "Average time (basic): ${BASIC_AVG}ms"
echo

# Benchmark optimized version
echo "==================================="
echo "2. Optimized Zig Keyword Filter"
echo "==================================="
echo

TOTAL_TIME=0

for i in $(seq 1 $RUNS); do
    echo "Run $i/$RUNS..."
    OUTPUT=$(./optimized/zig/filter_keywords_optimized data/test_hebrew_large.txt 2>&1)
    TIME=$(echo "$OUTPUT" | grep "Time elapsed:" | awk '{print $3}' | sed 's/ms//')
    TOTAL_TIME=$((TOTAL_TIME + TIME))
    echo "  Time: ${TIME}ms"
done

OPTIMIZED_AVG=$((TOTAL_TIME / RUNS))
echo
echo "Average time (optimized): ${OPTIMIZED_AVG}ms"
echo

# Calculate speedup
SPEEDUP=$(echo "scale=2; $BASIC_AVG / $OPTIMIZED_AVG" | bc)

echo "=========================================="
echo "RESULTS SUMMARY"
echo "=========================================="
echo
echo "Test Configuration:"
echo "  - Keywords: 50 Hebrew words"
echo "  - File size: $FILE_SIZE"
echo "  - Runs per test: $RUNS"
echo
echo "Performance Results:"
echo "  Basic version:     ${BASIC_AVG}ms"
echo "  Optimized version: ${OPTIMIZED_AVG}ms"
echo "  Speedup:           ${SPEEDUP}x"
echo
echo "The optimized parallel version is ${SPEEDUP}x faster!"
echo "=========================================="
