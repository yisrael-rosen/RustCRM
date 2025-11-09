#!/bin/bash

# Test: Performance with large WASM-like base64 strings

echo "Testing Large WASM Performance Impact"
echo "======================================"
echo ""

# Create test HTML with large base64 (simulating WASM)
create_test_file() {
    local size_kb=$1
    local filename=$2

    echo "Creating ${size_kb}KB test file: $filename"

    cat > "$filename" <<EOF
<!DOCTYPE html>
<html>
<head><title>Test</title></head>
<body>
<h1>Large WASM Test</h1>

<script>
// Simulated WASM module (large base64)
const wasmCode = "
EOF

    # Generate random base64-like data
    # Each line ~80 chars, so ~13 lines per KB
    local lines=$((size_kb * 13))

    for i in $(seq 1 $lines); do
        # Generate random base64 characters
        tr -dc 'A-Za-z0-9+/' < /dev/urandom | head -c 80 >> "$filename"
        echo "" >> "$filename"
    done

    # Embed a keyword somewhere in the middle
    echo "16TXldem16DXldeS16jXpNeZ15Qg" >> "$filename"  # Base64 keyword!

    # Continue with more random data
    for i in $(seq 1 100); do
        tr -dc 'A-Za-z0-9+/' < /dev/urandom | head -c 80 >> "$filename"
        echo "" >> "$filename"
    done

    cat >> "$filename" <<'EOF'
";

WebAssembly.instantiate(atob(wasmCode));
</script>

<p>Regular content with לקוחות and מכירות</p>

</body>
</html>
EOF

    local actual_size=$(du -k "$filename" | cut -f1)
    echo "  Actual size: ${actual_size}KB"
}

# Test different sizes
echo "Creating test files..."
echo ""

create_test_file 10 "data/test_wasm_10kb.html"
create_test_file 100 "data/test_wasm_100kb.html"
create_test_file 500 "data/test_wasm_500kb.html"
create_test_file 1000 "data/test_wasm_1mb.html"
create_test_file 5000 "data/test_wasm_5mb.html"

echo ""
echo "Test files created!"
echo ""
echo "File sizes:"
ls -lh data/test_wasm_*.html

echo ""
echo "======================================"
echo "Performance Test Scenarios:"
echo "======================================"
echo ""
echo "Scenario 1: Current approach (scan everything)"
echo "  - Extract entire WASM string"
echo "  - Scan all 6.7 MB for keywords"
echo "  - Expected: SLOW for large files"
echo ""
echo "Scenario 2: Smart skipping (proposed)"
echo "  - Skip strings > 500 KB"
echo "  - Or: Sample every N bytes"
echo "  - Expected: FAST, might miss some"
echo ""
echo "Scenario 3: Heuristic-based"
echo "  - Detect WASM signature (AGFsbQ)"
echo "  - Scan only data sections"
echo "  - Expected: MEDIUM speed, good coverage"
echo ""
echo "To benchmark, we need to implement these approaches..."
echo ""
echo "======================================"
echo "Question: What's the right trade-off?"
echo "======================================"
echo ""
echo "Options:"
echo ""
echo "1. Skip large strings entirely"
echo "   Pros: Fast"
echo "   Cons: Might miss keywords in large WASM"
echo ""
echo "2. Sample large strings (every 10 KB)"
echo "   Pros: Balance of speed and coverage"
echo "   Cons: Probabilistic (might miss)"
echo ""
echo "3. Set size limit per file"
echo "   Pros: Predictable performance"
echo "   Cons: Need to choose good limit"
echo ""
echo "4. Smart WASM detection"
echo "   Pros: Optimal for WASM specifically"
echo "   Cons: More complex code"
echo ""
echo "Recommendation:"
echo "  For strings > 500 KB:"
echo "    - Check if starts with 'AGFsbQ' (WASM signature)"
echo "    - If yes: Skip (WASM binary, keywords unlikely)"
echo "    - If no: Sample every 100 KB"
echo "  Rationale:"
echo "    - Keywords are 20-50 bytes"
echo "    - Unlikely to be in 5 MB WASM binary"
echo "    - If attacker uses large WASM, it's for obfuscation"
echo "      → Send entire file to LLM anyway!"
