#!/bin/bash

set -e

echo "Building all implementations..."
echo ""

# Build Zig
echo "Building Zig..."
cd zig
zig build-exe filter.zig -O ReleaseFast
echo "✓ Zig build complete"
cd ..

# Build Rust
echo "Building Rust..."
cd rust
cargo build --release
echo "✓ Rust build complete"
cd ..

# Build Go
echo "Building Go..."
cd go
go build -o filter filter.go
echo "✓ Go build complete"
cd ..

echo ""
echo "All builds completed successfully!"
