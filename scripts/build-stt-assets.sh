#!/usr/bin/env bash
#
# Builds the speech-to-text assets behind live subtitles:
#   1. subtitles-worker.<hash>.js — parakeet.js + onnxruntime-web's native
#      WebGPU EP entry bundled into a classic Worker script (esbuild)
#   2. vad.<hash>.js — @ricky0123/vad-web (Silero VAD) + onnxruntime-web
#      bundled as an ES module, dynamic-import()ed on the main thread
#   3. The onnxruntime runtime pair + the VAD model/worklet, under stable
#      names (the consuming plugin serves everything from a gem-version-
#      stamped URL). The ort module glue ships under a .js name:
#      nginx serves .mjs as application/octet-stream, which module imports
#      hard-reject, so nothing user-facing may carry a .mjs extension.
#
# Model weights (~200-400MB per model) are NOT built or committed: they come
# from HuggingFace at runtime (or a voice_stt_model_base_url mirror).
#
# Versions are pinned via package.json devDependencies (parakeet.js,
# @ricky0123/vad-web). Commit the regenerated vendor/stt/.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GEM_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUTPUT_DIR="${GEM_ROOT}/vendor/stt"

cd "${GEM_ROOT}"
pnpm install --silent

pkg_version() {
  node -p "JSON.parse(require('fs').readFileSync('node_modules/$1/package.json')).version"
}

PARAKEET_ORT_VERSION="$(pkg_version onnxruntime-web)"
VAD_VERSION="$(pkg_version "@ricky0123/vad-web")"
VAD_ORT_VERSION="$(pkg_version "@ricky0123/vad-web/node_modules/onnxruntime-web" 2>/dev/null || pkg_version onnxruntime-web)"

echo "==> Step 1: Bundle the transcription worker (parakeet.js + ort ${PARAKEET_ORT_VERSION})"

WORKER_TMP="$(mktemp --suffix=.js)"
VAD_TMP="$(mktemp --suffix=.vad.js)"
trap 'rm -f "${WORKER_TMP}" "${VAD_TMP}"' EXIT

# parakeet.js imports the default (JSEP) entry; the alias swaps it for the
# native WebGPU EP build, whose MatMulNBits handles the 2-bit and 4-bit
# encoders JSEP rejects or mis-executes.
pnpm exec esbuild "${GEM_ROOT}/src/stt-worker/worker.js" \
  --bundle --format=iife --minify \
  --alias:onnxruntime-web=onnxruntime-web/webgpu \
  --outfile="${WORKER_TMP}"

echo "==> Step 2: Bundle the VAD module (@ricky0123/vad-web ${VAD_VERSION})"

pnpm exec esbuild "${GEM_ROOT}/src/stt-worker/vad-entry.js" \
  --bundle --format=esm --minify --outfile="${VAD_TMP}"

echo "==> Step 3: Emit assets"

if [ "${VAD_ORT_VERSION}" != "${PARAKEET_ORT_VERSION}" ]; then
  echo "ERROR: vad-web resolved onnxruntime-web ${VAD_ORT_VERSION}, expected ${PARAKEET_ORT_VERSION}." >&2
  echo "       Both bundles must share one runtime dir; align the pins." >&2
  exit 1
fi

rm -rf "${OUTPUT_DIR}"
ORT_DIR="ort"
VAD_DIR="vad"
mkdir -p "${OUTPUT_DIR}/${ORT_DIR}" "${OUTPUT_DIR}/${VAD_DIR}"

install -m 644 "${WORKER_TMP}" "${OUTPUT_DIR}/subtitles-worker.js"
install -m 644 "${VAD_TMP}" "${OUTPUT_DIR}/vad.js"

# One runtime pair serves both consumers via explicit {mjs, wasm} URLs; the
# asyncify build (what the webgpu entry loads) is a superset of the plain
# wasm one, so the VAD's wasm-only frontend runs on it too.
install -m 644 node_modules/onnxruntime-web/dist/ort-wasm-simd-threaded.asyncify.wasm \
  "${OUTPUT_DIR}/${ORT_DIR}/ort-wasm-simd-threaded.asyncify.wasm"
install -m 644 node_modules/onnxruntime-web/dist/ort-wasm-simd-threaded.asyncify.mjs \
  "${OUTPUT_DIR}/${ORT_DIR}/ort-wasm-simd-threaded.asyncify.js"

install -m 644 node_modules/@ricky0123/vad-web/dist/silero_vad_v5.onnx \
  node_modules/@ricky0123/vad-web/dist/silero_vad_legacy.onnx \
  node_modules/@ricky0123/vad-web/dist/vad.worklet.bundle.min.js \
  "${OUTPUT_DIR}/${VAD_DIR}/"

echo "==> Build complete!"
ls -la "${OUTPUT_DIR}"
