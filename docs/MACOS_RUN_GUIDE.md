# Running OpenDLSS-NR on macOS

A complete guide to building, verifying, and running OpenDLSS-NR on macOS (Apple Silicon & Intel).

---

## 1. Overview & Architecture

**OpenDLSS-NR** contains two complementary implementations of NVIDIA's DLSS 5 Neural Rendering (NR) network (a 71-block Swin / ViT U-Net with FP8 E4M3 arithmetic and FP16 accumulation):

| Component | Target Architecture | macOS Status | Details |
| :--- | :--- | :--- | :--- |
| **WebGPU Port** (`ports/browser-webgpu/`) | WebGPU (Metal 3 on macOS) | **Fully Supported & Functional** | Runs bit-exact FP8/FP16 network emulation in pure WGSL shaders using Apple Silicon Metal 3. |
| **Native C++ Tools** (`dlss5vk`, `dump_numerics`) | Apple Clang / C++20 | **Fully Compiles & Runs** | Host parsing, CPU arithmetic reference, model loading logic, and numerics validation. |
| **PTX Kernel Pipeline** (`scripts/ptx/`) | Python 3 + NumPy | **Fully Functional** | Emits all 78 specialized Ada tensor-core PTX kernel variations. |
| **GLSL Compute Shaders** (`shaders/*.comp`) | SPIR-V 1.6 / Vulkan 1.3 | **Fully Compiles** | Compiles all 13 GLSL compute shaders to `.spv` via macOS Universal `glslang`. |
| **Native GPU Execution** (`dlss5vk bench/parity`) | NVIDIA Ada GPU (RTX 40-series) | *Hardware Limited* | Physical GPU dispatches require NVIDIA Ada tensor core extensions (`VK_NV_cuda_kernel_launch`, `VK_NV_cooperative_matrix2`). Non-NVIDIA GPUs (including Apple Silicon) run via the **WebGPU Port**. |

---

## 2. Prerequisites

Verify that the following standard development tools are available on your Mac:

1. **Xcode Command Line Tools** (Apple Clang C++20):
   ```bash
   clang++ --version
   ```
   *(If not installed, run: `xcode-select --install`)*

2. **Node.js & npm** (Node 18+):
   ```bash
   node -v
   npm -v
   ```

3. **Python 3 with NumPy**:
   ```bash
   python3 -c "import numpy; print(numpy.__version__)"
   ```
   *(If numpy is missing, run: `python3 -m pip install --user numpy`)*

4. **A WebGPU-enabled Browser**:
   * **Brave Browser** (auto-detected at `/Applications/Brave Browser.app`)
   * **Google Chrome** (`/Applications/Google Chrome.app`)
   * **Microsoft Edge** (`/Applications/Microsoft Edge.app`)
   * **Safari** (Safari 18+ with WebGPU enabled)

---

## 3. Quick Start (Build & Test in 2 Commands)

From the root of the repository (`/Users/neeth/Programs/OpenDLSS`):

```bash
# 1. Fetch tools, compile shaders, build native binaries, and bundle the WebGPU demo
./scripts/build_mac.sh

# 2. Run the full verification test suite
./scripts/test_mac.sh
```

---

## 4. Building the Project

The macOS build system is driven by [`./scripts/build_mac.sh`](file:///Users/neeth/Programs/OpenDLSS/scripts/build_mac.sh). It executes four automated stages:

```bash
./scripts/build_mac.sh
```

### What `build_mac.sh` Does:
1. **Fetches portable dependencies** ([`scripts/fetch_tools.sh`](file:///Users/neeth/Programs/OpenDLSS/scripts/fetch_tools.sh)):
   - Downloads `glslang 16.6.0` (macOS universal release).
   - Clones tagged `Vulkan-Headers` (`v1.4.363`) and `volk` (`vulkan-sdk-1.4.357.0`).
2. **Builds Shaders and PTX Kernels** ([`scripts/build_shaders.sh`](file:///Users/neeth/Programs/OpenDLSS/scripts/build_shaders.sh)):
   - Compiles all 13 `shaders/*.comp` compute shaders to `build/shaders/*.spv`.
   - Generates all 78 specialized PTX kernel files into `build/ptx/*.ptx`.
3. **Builds Native C++ Binaries**:
   - `build/dlss5vk`: Native host CLI linked with Clang and Volk.
   - `build/dump_numerics`: C++ reference arithmetic exporter.
4. **Builds WebGPU Demo**:
   - Installs npm dependencies in `ports/browser-webgpu/`.
   - Compiles esbuild bundles to `ports/browser-webgpu/demo/dist/`.

---

## 5. Running the Test Suite

Run [`./scripts/test_mac.sh`](file:///Users/neeth/Programs/OpenDLSS/scripts/test_mac.sh) to execute the end-to-end mathematical verification:

```bash
./scripts/test_mac.sh
```

### The 4 Verification Stages:

1. **PTX Fast Divmod Test** (`scripts/ptx/test_fast_divmod.py`):
   - Tests the PTX reciprocal divider emulation over all $n < 2^{24}$ for exactness against unsigned integer division.
2. **Native C++ Reference Dumper** (`build/dump_numerics`):
   - Computes reference E4M3/F16 conversions, SiLU tables, and Ada FP8/FP16 FDPA accumulations directly on the CPU, generating `ports/browser-webgpu/web/fixtures/numerics.bin`.
3. **WebGPU JavaScript Oracle** (`tools/check_numerics.mjs`):
   - Validates that the JavaScript publication implementation matches the C++ reference for 65,536 half-precision and 32,768 arbitrary floating-point patterns.
4. **Headless Metal WebGPU Self-Test** (`tools/headless.mjs selftest`):
   - Spawns headless Chromium/Brave with `--enable-unsafe-webgpu`.
   - Executes WGSL compute shaders on **Apple Metal 3** and verifies bit-for-bit equivalence against the reference oracle.

---

## 6. Running the WebGPU Browser Implementation

To launch the local WebGPU development server:

```bash
./scripts/run_webgpu.sh [port]
```
*(Default port is `8099`)*

Once started, open any of the following URLs in your browser:

### 1. Interactive Metal Self-Test
👉 **`http://localhost:8099/web/selftest.html`**
- Displays an interactive live matrix of every arithmetic primitive executed on your Mac's Metal GPU vs. the CPU oracle.

### 2. Parity Test Harness
👉 **`http://localhost:8099/web/parity.html`**
- Gated parity checker that compares every block boundary byte-for-byte against recorded reference fixtures.

### 3. Interactive 3D Demo
👉 **`http://localhost:8099/demo/index.html`**
- 3D WebGI scene viewer integrated with the DLSS 5 Neural Rendering WebGPU pipeline.
- **Built-in Fallback Scene**: If external scene packs like Cowboy Gramps are not mounted, the demo automatically falls back to an interactive metallic 3D test scene so the viewer always runs out of the box.
- **Drag & Drop Local Models**: You can drag and drop any `.glb` or `.gltf` 3D model directly onto the browser canvas to view and test custom models.
- **Scene Dropdown**: Switch between the Built-in 3D Demo, Cowboy Gramps, or click "Open Local Model..." to browse for a 3D file on your Mac.
- Supports keyboard and mouse controls:
  - <kbd>Drag</kbd> to orbit camera
  - <kbd>Scroll</kbd> to zoom
  - <kbd>R</kbd> toggle render
  - <kbd>L</kbd> live rendering toggle
  - <kbd>F6</kbd> compare split-screen view

---

## 7. Mounting External Model Weights & Fixtures (Optional)

The repository does not bundle proprietary model weights or multi-gigabyte scene assets. If you supply weights or recorded captures, mount them via environment variables:

| Variable | Default Path | Description |
| :--- | :--- | :--- |
| `NR_WEIGHTS` | `models/nr` | The 141 MiB DLSS 5 model directory (`manifest.json` and `model/stages/*`). |
| `NR_FIXTURES` | None | Parity captures (`nr512`, `nr768`) containing recorded tensor boundaries. |
| `NR_SCENES` | None | Demo 3D scenes (e.g. Cowboy Gramps, Bistro: `view.json`, `.glb`, `lighting.hdr`). |

### Example with custom mounts:
```bash
NR_WEIGHTS="/path/to/my/models/nr" \
NR_FIXTURES="/path/to/my/fixtures" \
./scripts/run_webgpu.sh
```

---

## 8. Troubleshooting

### Specifying a Custom Browser Path
If your browser is in a non-standard location, set the `CHROME` environment variable:
```bash
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ./scripts/test_mac.sh
```

### Seeing the Test in a Real Window
To watch the browser tests run with a visible window instead of headless:
```bash
NR_HEADED=1 node ports/browser-webgpu/tools/headless.mjs selftest
```

### Clean Rebuild
To delete build artifacts and rebuild from scratch:
```bash
rm -rf build ports/browser-webgpu/demo/dist
./scripts/build_mac.sh
```
