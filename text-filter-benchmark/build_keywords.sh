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

# Build HTML keyword filters
echo "Building HTML keyword filters..."

echo "Building basic HTML keyword filter..."
zig build-exe zig/filter_html_keywords.zig \
    -O ReleaseFast \
    -femit-bin=zig/filter_html_keywords

echo "✓ Basic HTML version built: zig/filter_html_keywords"
echo

echo "Building optimized HTML keyword filter..."
zig build-exe optimized/zig/filter_html_keywords_optimized.zig \
    -O ReleaseFast \
    -femit-bin=optimized/zig/filter_html_keywords_optimized

echo "✓ Optimized HTML version built: optimized/zig/filter_html_keywords_optimized"
echo

echo "Building multi-layer content classifier..."
zig build-exe zig/filter_html_classifier.zig \
    -O ReleaseFast \
    -femit-bin=zig/filter_html_classifier

echo "✓ Classifier built: zig/filter_html_classifier"
echo

echo "Building extended multi-layer classifier (215 keywords)..."
zig build-exe zig/filter_html_classifier_extended.zig \
    -O ReleaseFast \
    -femit-bin=filter_html_classifier_extended

echo "✓ Extended classifier built: filter_html_classifier_extended"
echo

echo "Build completed successfully!"
echo
echo "Usage:"
echo "  Text filters:"
echo "    ./zig/filter_keywords <input_file>"
echo "    ./optimized/zig/filter_keywords_optimized <input_file>"
echo
echo "  HTML filters:"
echo "    ./zig/filter_html_keywords <input_file.html>"
echo "    ./optimized/zig/filter_html_keywords_optimized <input_file.html>"
echo
echo "  Multi-layer classifiers:"
echo "    ./zig/filter_html_classifier <input_file.html>  # 86 keywords, 57% LLM reduction"
echo "    ./filter_html_classifier_extended <input_file.html>  # 215 keywords, 71% LLM reduction"
echo
echo "  Batch tests:"
echo "    ./test_classifier_batch.sh  # Test original (86 keywords)"
echo "    ./test_classifier_extended_batch.sh  # Test extended (215 keywords)"
