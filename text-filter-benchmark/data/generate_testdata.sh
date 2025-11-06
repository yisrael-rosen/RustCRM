#!/bin/bash
# Generate test data: 1 million lines of varied text

OUTPUT="testdata.txt"
LINES=1000000

echo "Generating $LINES lines of test data..."

for i in $(seq 1 $LINES); do
    case $((i % 10)) in
        0) echo "ERROR: Database connection failed at line $i" ;;
        1) echo "INFO: Processing request $i successfully" ;;
        2) echo "WARNING: High memory usage detected: ${i}MB" ;;
        3) echo "DEBUG: Function call trace: module_${i}.func()" ;;
        4) echo "SUCCESS: Transaction $i completed" ;;
        5) echo "CRITICAL: Security alert on port $i" ;;
        6) echo "User session $i started at $(date +%H:%M:%S)" ;;
        7) echo "Network packet received from 192.168.1.$((i % 255))" ;;
        8) echo "Cache miss for key: item_${i}_data" ;;
        9) echo "Performance metric: ${i}ms response time" ;;
    esac
done > $OUTPUT

echo "Generated $OUTPUT with $(wc -l < $OUTPUT) lines"
