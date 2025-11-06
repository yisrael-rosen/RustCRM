# Text Filter Performance Benchmark Results

## Test Environment
- **Platform**: Linux 4.4.0
- **Test Data**: 217,615 lines (8.9 MB)
- **Search Pattern**: "ERROR"
- **Matching Lines**: 21,761 (10% of total)
- **Output Size**: 1,055,183 bytes
- **Runs per Implementation**: 5

## Language Versions
- **Zig**: 0.15.2 (compiled with `-O ReleaseFast`)
- **Rust**: 2021 edition (compiled with `--release`, LTO enabled, opt-level=3)
- **Go**: 1.21+ (standard build)

## Performance Results

### Zig
```
Run 1: 17ms
Run 2: 16ms
Run 3: 16ms
Run 4: 18ms
Run 5: 16ms
Average: 16.6ms
```

### Rust
```
Run 1: 21ms
Run 2: 22ms
Run 3: 21ms
Run 4: 25ms
Run 5: 23ms
Average: 22.4ms
```

### Go
```
Run 1: 37ms
Run 2: 36ms
Run 3: 37ms
Run 4: 36ms
Run 5: 37ms
Average: 36.6ms
```

## Performance Comparison

| Language | Average Time | vs Fastest | Throughput (MB/s) |
|----------|-------------|------------|-------------------|
| **Zig**  | 16.6ms      | 1.00x (baseline) | 536 MB/s      |
| **Rust** | 22.4ms      | 1.35x slower     | 397 MB/s      |
| **Go**   | 36.6ms      | 2.20x slower     | 243 MB/s      |

## Analysis

### 1. **Zig - Fastest (16.6ms average)**
   - **Strengths**:
     - Reads entire file into memory at once (zero-copy approach)
     - Minimal abstractions and overhead
     - Highly optimized memory operations
     - Very consistent performance (16-18ms range)

   - **Approach**: Loads complete file into memory, uses `splitSequence` for line iteration, simple substring matching

### 2. **Rust - Second Fastest (22.4ms average, 35% slower than Zig)**
   - **Strengths**:
     - Excellent performance with safe abstractions
     - Buffered I/O with `BufReader`
     - Zero-cost abstractions philosophy
     - Good memory management

   - **Approach**: Buffered line-by-line reading, uses `String` accumulation, safe memory handling

   - **Variance**: Slightly higher (21-25ms range), possibly due to dynamic memory allocations

### 3. **Go - Slowest (36.6ms average, 120% slower than Zig)**
   - **Strengths**:
     - Very clean and readable code
     - Consistent performance (36-37ms range)
     - Good developer experience
     - Built-in garbage collector

   - **Approach**: Uses `bufio.Scanner` for line-by-line reading, `strings.Builder` for accumulation

   - **Overhead**: GC pauses and runtime overhead contribute to slower performance

## Key Takeaways

1. **Zig wins on raw performance**: ~120% faster than Go, ~35% faster than Rust
   - Achieves this through aggressive optimizations and zero-abstraction I/O

2. **Rust offers best balance**: Near-native performance with memory safety guarantees
   - Only 35% slower than Zig while providing compile-time safety

3. **Go prioritizes simplicity**: Slowest but most readable code
   - Trade-off: Simpler concurrency model and better developer ergonomics

4. **All three are production-ready**: Even Go's "slow" 37ms is excellent for this task
   - Processing 8.9 MB in under 40ms is fast in absolute terms

## Implementation Characteristics

### Memory Strategy
- **Zig**: Loads entire file (8.9 MB) into memory at once
- **Rust**: Streams line-by-line with buffering
- **Go**: Streams line-by-line with buffering

### Trade-offs
- **Zig**: Maximum speed, but requires file size in memory
- **Rust**: Good balance of speed and safety
- **Go**: Prioritizes code simplicity and maintainability

## Conclusion

For **raw performance**: Choose **Zig**
For **safety + performance**: Choose **Rust**
For **simplicity + good performance**: Choose **Go**

The choice depends on your priorities:
- Need every millisecond? → Zig
- Want safety without significant performance loss? → Rust
- Prefer simple, maintainable code? → Go
