# Guide: Running OpenDLSS-NR on macOS

This guide provides instructions for building, testing, and running **OpenDLSS-NR** on macOS (Apple Silicon M-series and Intel Macs).

---

## Architecture at a Glance

OpenDLSS-NR contains two implementations of NVIDIA's DLSS 5 Neural Rendering network:

1. **WebGPU Port (`ports/browser-webgpu/`)**:
   - Primary route for macOS / Apple Silicon.
   - Emulates the full 71-block Swin / ViT network with FP8 (E4M3) and FP16 arithmetic using pure WGSL compute shaders.
   - Executes via WebGPU on top of **Apple Metal 3** with zero NVIDIA hardware requirements.
2. **Native C++ Tools (`src/`)**:
   - Host model parser, CPU arithmetic reference, and validation tools (`dlss5vk`, `dump_numerics`).
   - Compiles cleanly on macOS with Apple Clang C++20.
3. **PTX & Shader Pipelines (`shaders/`, `scripts/ptx/`)**:
   - Compiles all 13 GLSL compute shaders to SPIR-V 1.6 (`build/shaders/`).
   - Generates all 78 specialized Ada PTX kernels (`build/ptx/`).

---

## 1. Prerequisites

Ensure the following tools are available on your Mac:

| Dependency | Minimum Version | Check Command | Installation / Setup |
| :--- | :--- | :--- | :--- |
| **Apple Clang** | C++20 support | `clang++ --version` | `xcode-select --install` |
| **Node.js & npm** | Node 18+ | `node -v && npm -v` | Installed via Homebrew or official installer |
| **Python 3** | Python 3.9+ | `python3 --version` | Included with macOS / Xcode |
| **NumPy** | 1.20+ | `python3 -c "import numpy"` | `python3 -m pip install --user numpy` |
| **Chromium Browser** | WebGPU enabled | Auto-detected | Brave Browser, Google Chrome, or Microsoft Edge |

---

## 2. Quick Command Reference

```bash
# 1. Build everything (tools, shaders, PTX, C++ binaries, WebGPU bundles)
./scripts/build_mac.sh

# 2. Run the complete 4-stage arithmetic & Metal verification suite
./scripts/test_mac.sh

# 3. Start the WebGPU server
./scripts/run_webgpu.sh
```

---

## 3. What the Scripts Do

### [build_mac.sh](file:///Users/neeth/Programs/OpenDLSS/scripts/build_mac.sh)
- Invokes [`scripts/fetch_tools.sh`](file:///Users/neeth/Programs/OpenDLSS/scripts/fetch_tools.sh) to download macOS Universal `glslang 16.6.0`, `Vulkan-Headers`, and `volk`.
- Invokes [`scripts/build_shaders.sh`](file:///Users/neeth/Programs/OpenDLSS/scripts/build_shaders.sh) to compile all compute shaders and generate all 78 PTX variants.
- Compiles `build/dlss5vk` and `build/dump_numerics` using `clang++ -std=c++20`.
- Installs npm packages and builds WebGPU demo bundles via `node demo/build.mjs`.

### [test_mac.sh](file:///Users/neeth/Programs/OpenDLSS/scripts/test_mac.sh)
Runs 4 tests verifying bit-exact numerical parity:
1. **PTX divider regression test**: Emulates the PTX divider over all $n < 2^{24}$.
2. **C++ reference dumper**: Generates `ports/browser-webgpu/web/fixtures/numerics.bin` from the native C++ CPU reference.
3. **JavaScript oracle check**: Verifies JS bit-exactness over 65,536 half-float values.
4. **Headless WebGPU Metal 3 test**: Executes WGSL shaders on Apple Metal 3 and asserts zero mismatches against the oracle.

### [run_webgpu.sh](file:///Users/neeth/Programs/OpenDLSS/scripts/run_webgpu.sh)
Starts the local HTTP server hosting the WebGPU implementation on port `8099`.

---

## 4. WebGPU Web Interfaces

When `./scripts/run_webgpu.sh` is running, open the following endpoints in your browser:

* **Metal WebGPU Self-Test**:
  `http://localhost:8099/web/selftest.html`
  *Displays a live table comparing CPU oracle results vs. Metal 3 WGSL GPU results.*

* **Parity Test Harness**:
  `http://localhost:8099/web/parity.html`
  *Checks full network frame boundaries against reference captures.*

* **Interactive 3D Demo**:
  `http://localhost:8099/demo/index.html`
  *Interactive scene renderer demonstrating the neural rendering pipeline.*

---

## 5. Environment Variables & Custom Paths

You can configure paths when mounting external weights or scenes:

```bash
# Point to external model weights:
export NR_WEIGHTS="/path/to/models/nr"

# Point to external parity fixtures:
export NR_FIXTURES="/path/to/fixtures"

# Point to external 3D scenes:
export NR_SCENES="/path/to/scenes"

# Launch server with the mounted assets:
./scripts/run_webgpu.sh
```

To use a specific browser binary for tests:
```bash
CHROME="/Applications/Brave Browser.app/Contents/MacOS/Brave Browser" ./scripts/test_mac.sh
```

To run browser tests with a visible window instead of headless mode:
```bash
NR_HEADED=1 node ports/browser-webgpu/tools/headless.mjs selftest
```
