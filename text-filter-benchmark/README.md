# Text Filter Performance Benchmark

A performance comparison of text filtering implementations in Zig, Rust, and Go.

## Overview

This benchmark compares three implementations of a text filtering engine that:
- Reads a large text file (1 million lines)
- Filters lines containing a search pattern
- Counts matches and measures execution time

## Structure

```
text-filter-benchmark/
├── zig/          # Zig implementation
├── rust/         # Rust implementation
├── go/           # Go implementation
├── data/         # Test data
├── build.sh      # Build all implementations
└── benchmark.sh  # Run performance tests
```

## Implementations

### Zig (filter.zig)
- Uses Zig 0.15.2
- Compiled with `-O ReleaseFast`
- Reads entire file into memory for maximum performance

### Rust (src/main.rs)
- Uses Rust with standard library
- Compiled with `--release` (opt-level=3, LTO enabled)
- Buffered line-by-line reading

### Go (filter.go)
- Uses Go 1.21+
- Standard go build
- Buffered scanning with strings.Builder

## Building

```bash
chmod +x build.sh
./build.sh
```

## Running Benchmarks

```bash
chmod +x benchmark.sh
./benchmark.sh
```

The benchmark will:
1. Run each implementation 5 times
2. Calculate average execution time
3. Display results for comparison

## Test Data

The test data consists of 1 million lines with varied log message patterns:
- ERROR messages
- INFO messages
- WARNING messages
- DEBUG traces
- SUCCESS confirmations
- CRITICAL alerts
- User sessions
- Network packets
- Cache events
- Performance metrics

## Performance Metrics

Each implementation reports:
- Total lines processed
- Matching lines found
- Execution time (milliseconds)
- Output size (bytes)
