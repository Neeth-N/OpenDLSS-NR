#!/usr/bin/env bash
set -euo pipefail

# Fetch portable toolchain into tools/ for macOS / Linux:
# glslang (macOS universal zip), Vulkan-Headers (git clone), volk (git clone)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="$ROOT_DIR/tools"
mkdir -p "$TOOLS_DIR"

GLSLANG_VERSION="16.6.0"
VULKAN_HEADERS_TAG="v1.4.363"
VOLK_TAG="vulkan-sdk-1.4.357.0"

# 1. glslang
if [[ ! -x "$TOOLS_DIR/glslang/bin/glslang" ]]; then
  echo "==> Fetching glslang $GLSLANG_VERSION for macOS..."
  GLSLANG_ZIP="$TOOLS_DIR/glslang.zip"
  curl -fsSL -o "$GLSLANG_ZIP" "https://github.com/KhronosGroup/glslang/releases/download/${GLSLANG_VERSION}/glslang-${GLSLANG_VERSION}-macos-universal-release.zip"
  mkdir -p "$TOOLS_DIR/glslang"
  unzip -q -o "$GLSLANG_ZIP" -d "$TOOLS_DIR/glslang"
  rm -f "$GLSLANG_ZIP"
  chmod +x "$TOOLS_DIR/glslang/bin/glslang"
fi
"$TOOLS_DIR/glslang/bin/glslang" --version | head -n 1

# 2. Vulkan-Headers
if [[ ! -f "$TOOLS_DIR/Vulkan-Headers/include/vulkan/vulkan.h" ]]; then
  echo "==> Fetching Vulkan-Headers ($VULKAN_HEADERS_TAG)..."
  git clone --depth 1 --branch "$VULKAN_HEADERS_TAG" https://github.com/KhronosGroup/Vulkan-Headers.git "$TOOLS_DIR/Vulkan-Headers"
fi

# 3. volk
if [[ ! -f "$TOOLS_DIR/volk/volk.c" ]]; then
  echo "==> Fetching volk ($VOLK_TAG)..."
  git clone --depth 1 --branch "$VOLK_TAG" https://github.com/zeux/volk.git "$TOOLS_DIR/volk"
fi

echo "==> Tools ready in $TOOLS_DIR"
