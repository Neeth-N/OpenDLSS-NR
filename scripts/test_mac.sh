#!/usr/bin/env bash
set -euo pipefail

# Test suite runner for macOS:
# 1. PTX fast divider regression test (Python + numpy)
# 2. C++ dump_numerics against the native CPU reference
# 3. WebGPU numerical check on CPU (JS oracle vs C++ reference)
# 4. WebGPU Metal shader execution in headless browser (WGSL vs C++ reference)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== [1/4] Running PTX fast divmod test (Python/numpy) ==="
python3 "$ROOT_DIR/scripts/ptx/test_fast_divmod.py" 4

echo ""
echo "=== [2/4] Running C++ dump_numerics fixture generation ==="
"$ROOT_DIR/build/dump_numerics"

echo ""
echo "=== [3/4] Running WebGPU JavaScript oracle numerics check ==="
node "$ROOT_DIR/ports/browser-webgpu/tools/check_numerics.mjs"

echo ""
echo "=== [4/4] Running WebGPU Metal shader self-test in headless browser ==="
node "$ROOT_DIR/ports/browser-webgpu/tools/headless.mjs" selftest

echo ""
echo "===================================="
echo "  ALL MACOS COMPATIBILITY TESTS PASSED!"
echo "===================================="
