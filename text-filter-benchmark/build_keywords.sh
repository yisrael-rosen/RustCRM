#!/bin/bash

# Build script for Zig keyword filters

set -e

echo "Building Zig keyword filter implementations..."
echo

# Check if Zig is installed
if ! command -v zig &> /dev/null; then
    if [ -f "/tmp/zig-linux-x86_64-0.13.0/zig" ]; then
        export PATH="/tmp/zig-linux-x86_64-0.13.0:$PATH"
    else
        echo "Error: Zig compiler not found"
        exit 1
    fi
fi

ZIG_VERSION=$(zig version)
echo "Using Zig version: $ZIG_VERSION"
echo

# Build basic version
echo "Building basic Zig keyword filter..."
zig build-exe zig/filter_keywords.zig \
    -O ReleaseFast \
    -femit-bin=zig/filter_keywords

echo "✓ Basic version built: zig/filter_keywords"
echo

# Build optimized version
echo "Building optimized Zig keyword filter..."
zig build-exe optimized/zig/filter_keywords_optimized.zig \
    -O ReleaseFast \
    -femit-bin=optimized/zig/filter_keywords_optimized

echo "✓ Optimized version built: optimized/zig/filter_keywords_optimized"
echo

echo "Build completed successfully!"
echo
echo "Usage:"
echo "  ./zig/filter_keywords <input_file>"
echo "  ./optimized/zig/filter_keywords_optimized <input_file>"
