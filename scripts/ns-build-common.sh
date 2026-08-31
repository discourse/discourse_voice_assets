# Shared helpers for the noise-suppression engine build scripts
# (build-*-worklet.sh). Sourced, not executed.
#
# Each engine ships under vendor/<engine>/ with stable filenames: the
# consuming plugin serves the whole vendor tree from a gem-version-stamped
# URL, so cache busting comes from releasing a new gem version, not from
# content-hashed names.

# bundle_worklet <engine> <out_file>
bundle_worklet() {
  local engine="$1"
  local out="$2"
  cd "${GEM_ROOT}"
  pnpm install --silent
  pnpm exec esbuild "${GEM_ROOT}/src/${engine}-worklet/noise-suppression-processor.js" \
    --bundle --format=iife --minify --outfile="${out}"
}

# emit_ns_assets <engine> <worklet_bundle> <wasm_file> [model_file]
#
# Copies the artifacts into vendor/<engine>/ under their stable names.
emit_ns_assets() {
  local engine="$1"
  local bundle="$2"
  local wasm="$3"
  local model="${4:-}"

  local output_dir="${GEM_ROOT}/vendor/${engine}"

  rm -rf "${output_dir}"
  mkdir -p "${output_dir}"

  install -m 644 "${bundle}" "${output_dir}/${engine}-worklet.js"
  install -m 644 "${wasm}" "${output_dir}/${engine}.wasm"
  if [ -n "${model}" ]; then
    install -m 644 "${model}" "${output_dir}/${engine}-model.bin"
  fi

  echo "==> Build complete!"
  ls -la "${output_dir}"
}
