#!/usr/bin/env python3
import sys

def generate_testdata(filename, num_lines):
    print(f"Generating {num_lines:,} lines of test data...")

    patterns = [
        lambda i: f"ERROR: Database connection failed at line {i}",
        lambda i: f"INFO: Processing request {i} successfully",
        lambda i: f"WARNING: High memory usage detected: {i}MB",
        lambda i: f"DEBUG: Function call trace: module_{i}.func()",
        lambda i: f"SUCCESS: Transaction {i} completed",
        lambda i: f"CRITICAL: Security alert on port {i}",
        lambda i: f"User session {i} started at 12:00:00",
        lambda i: f"Network packet received from 192.168.1.{i % 255}",
        lambda i: f"Cache miss for key: item_{i}_data",
        lambda i: f"Performance metric: {i}ms response time",
    ]

    with open(filename, 'w') as f:
        for i in range(1, num_lines + 1):
            line = patterns[i % 10](i)
            f.write(line + '\n')

            if i % 100000 == 0:
                print(f"  Written {i:,} lines...")

    print(f"✓ Generated {filename} with {num_lines:,} lines")

if __name__ == "__main__":
    generate_testdata("testdata.txt", 1_000_000)
