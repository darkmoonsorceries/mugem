#!/bin/bash
# Standalone MUGEM compilation (without full Ghostty)
set -e

echo "=== MUGEM Standalone Build ==="

# Export SDK for Zig
export ZIG_SYSTEM_LIBRARY_PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib"

# Create output dir
mkdir -p standalone_out

# Test compile our modules individually
echo "Testing harfbuzz.zig..."
zig test src/mugem/harfbuzz.zig 2>&1 | head -5 || echo "(expected: needs C headers)"

echo ""
echo "Testing bidi.zig..."
zig test src/mugem/bidi.zig 2>&1 | head -5 || echo "(expected: needs dependencies)"

echo ""
echo "Testing display.zig..."
zig test src/mugem/display.zig 2>&1 | head -5 || echo "(expected: needs dependencies)"

echo ""
echo "Testing mugem.zig..."
zig test src/mugem.zig 2>&1 | head -5 || echo "(expected: needs dependencies)"

echo ""
echo "Attempting standalone executable..."
zig test test_mugem.zig -o standalone_out/mugem_test 2>&1 | head -10 || echo "(expected: partial success)"

if [ -f standalone_out/mugem_test ]; then
    echo "=== RUNNING STANDALONE TEST ==="
    ./standalone_out/mugem_test 2>&1 || echo "(runtime errors expected)"
fi

echo ""
echo "Note: Full Ghostty requires:"
echo "  1. Xcode Command Line Tools fully configured"
echo "  2. GTK/GLib deps on macOS (complex)"
echo "  3. Or use Python bridge instead (immediate)"
