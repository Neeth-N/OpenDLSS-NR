#!/usr/bin/env bash
set -euo pipefail

# Runs the WebGPU implementation server on macOS
# Usage: ./scripts/run_webgpu.sh [port]

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${1:-8099}"

echo "Starting WebGPU port server on port $PORT..."
echo "Open in your browser:"
echo "  Self-Test (Metal WebGPU test): http://localhost:$PORT/web/selftest.html"
echo "  Parity verification:          http://localhost:$PORT/web/parity.html"
echo "  Interactive 3D Demo:          http://localhost:$PORT/demo/index.html"
echo ""

cd "$ROOT_DIR/ports/browser-webgpu"
exec node serve.mjs "$PORT"
