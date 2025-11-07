#!/bin/bash

set -e

echo "Building optimized implementations..."
echo ""

# Build Zig Optimized
echo "Building Zig Optimized..."
cd optimized/zig
zig build-exe filter_optimized.zig -O ReleaseFast
echo "✓ Zig optimized build complete"
cd ../..

# Build Rust Optimized
echo "Building Rust Optimized..."
cd optimized/rust
cargo build --release
echo "✓ Rust optimized build complete"
cd ../..

# Build Go Optimized
echo "Building Go Optimized..."
cd optimized/go
go build -o filter_optimized filter_optimized.go
echo "✓ Go optimized build complete"
cd ../..

echo ""
echo "All optimized builds completed successfully!"
