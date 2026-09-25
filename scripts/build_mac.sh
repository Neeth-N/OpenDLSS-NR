#!/usr/bin/env bash
set -euo pipefail

# Build script for macOS (Apple Silicon / Intel)
# Builds:
# 1. tools (glslang, Vulkan-Headers, volk)
# 2. shaders & PTX kernels (build/shaders/*.spv, build/ptx/*.ptx)
# 3. native host tools (build/dlss5vk, build/dump_numerics)
# 4. WebGPU browser port (npm install, demo bundles)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
OBJ_DIR="$BUILD_DIR/obj"
mkdir -p "$BUILD_DIR" "$OBJ_DIR"

echo "=== [1/4] Ensuring build tools are present ==="
"$ROOT_DIR/scripts/fetch_tools.sh"

echo "=== [2/4] Building shaders and PTX kernels ==="
"$ROOT_DIR/scripts/build_shaders.sh"

echo "=== [3/4] Building native C++ binaries (dlss5vk, dump_numerics) ==="
CXX="${CXX:-clang++}"
CC="${CC:-clang}"
CXXFLAGS="-std=c++20 -O2 -DVK_ENABLE_BETA_EXTENSIONS -I$ROOT_DIR/tools/Vulkan-Headers/include -I$ROOT_DIR/tools/volk -I$ROOT_DIR/src"
CFLAGS="-O2 -DVK_ENABLE_BETA_EXTENSIONS -I$ROOT_DIR/tools/Vulkan-Headers/include -I$ROOT_DIR/tools/volk"

SRC_FILES=(
  "src/reference.cpp"
  "src/nr_model.cpp"
  "src/verify.cpp"
  "src/nr_graph.cpp"
  "src/kernels.cpp"
  "src/vk_context.cpp"
  "src/main.cpp"
)

for src in "${SRC_FILES[@]}"; do
  base="$(basename "$src" .cpp)"
  echo "Compiling $src..."
  "$CXX" $CXXFLAGS -c "$ROOT_DIR/$src" -o "$OBJ_DIR/${base}.o"
done

echo "Compiling tools/volk/volk.c..."
"$CC" $CFLAGS -c "$ROOT_DIR/tools/volk/volk.c" -o "$OBJ_DIR/volk.o"

echo "Linking $BUILD_DIR/dlss5vk..."
"$CXX" "$OBJ_DIR"/*.o -o "$BUILD_DIR/dlss5vk"

echo "Compiling $BUILD_DIR/dump_numerics..."
"$CXX" $CXXFLAGS "$ROOT_DIR/ports/browser-webgpu/tools/dump_numerics.cpp" -o "$BUILD_DIR/dump_numerics"

echo "=== [4/4] Setting up WebGPU Port ==="
cd "$ROOT_DIR/ports/browser-webgpu"
if [[ ! -d "node_modules" ]]; then
  echo "Installing npm dependencies in ports/browser-webgpu..."
  npm install --no-audit --no-fund
fi

echo "Building demo bundles..."
node demo/build.mjs

echo ""
echo "=== Build Complete! ==="
echo "Binaries built:"
echo "  - $BUILD_DIR/dlss5vk"
echo "  - $BUILD_DIR/dump_numerics"
echo "WebGPU port ready in ports/browser-webgpu"
