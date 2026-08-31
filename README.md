# DiscourseVoiceAssets

Prebuilt browser media assets for Discourse voice/video chat (the `resenha`
plugin). The plugin's client features depend on ~75 MB of WebAssembly
binaries, ML models, and vendored SDK bundles; this gem carries those blobs so
they stay out of the main Discourse repository, along with the pinned,
reproducible build scripts that produce every artifact.

## What's vendored

| Directory | Contents | Source | License |
|---|---|---|---|
| `vendor/rnnoise` | RNNoise noise-suppression worklet + wasm (~130 KB) | [xiph/rnnoise](https://github.com/xiph/rnnoise) @ v0.1.1 | BSD-3-Clause |
| `vendor/dtln` | DTLN noise-suppression worklet + wasm (~6 MB) | [DataDog/dtln-rs](https://github.com/DataDog/dtln-rs) | Apache-2.0 |
| `vendor/dfn3` | DeepFilterNet3 worklet + wasm (~9.5 MB) + model (~8 MB) | [Rikorose/DeepFilterNet](https://github.com/Rikorose/DeepFilterNet) | MIT/Apache-2.0 |
| `vendor/stt` | Live-subtitles runtime: parakeet.js worker, Silero VAD, onnxruntime-web (~41 MB) | [parakeet.js](https://github.com/ysdede/parakeet.js), [@ricky0123/vad-web](https://github.com/ricky0123/vad), [onnxruntime-web](https://onnxruntime.ai) | Apache-2.0 / MIT |
| `vendor/mediapipe` | Background-blur segmentation: tasks-vision runtime + `selfie_segmenter.tflite` (~22 MB) | [MediaPipe](https://github.com/google-ai-edge/mediapipe), © Google | Apache-2.0 |
| `vendor/livekit` | Self-contained `livekit-client` ESM bundle (~530 KB) | [livekit-client](https://github.com/livekit/client-sdk-js) | Apache-2.0 |

The ~2.5 GB speech-to-text model weights are **not** vendored — they download
at runtime from HuggingFace (or a self-hosted mirror).

## How the plugin consumes it

```ruby
require "discourse_voice_assets"

DiscourseVoiceAssets::DIRECTORIES # => %w[dfn3 dtln livekit mediapipe rnnoise stt]
DiscourseVoiceAssets.vendor_path("stt") # absolute path to the vendored dir
```

At plugin activation the vendor tree is symlinked into the plugin's
`public/javascripts/<gem version>/`, and the server exposes that base path to
the client, so assets are served at
`/plugins/resenha/javascripts/<version>/<dir>/...`. Filenames are stable
across releases — the version-stamped URL provides the cache busting that
content hashes otherwise would (the `/plugins/` prefix is served with
long-lived immutable caching) — so bumping the gem requires no other plugin
change.

## Rebuilding assets

Everything under `vendor/` is generated. Upstreams are pinned
(git SHA or npm version); build scripts clone into the gitignored `upstream/`
directory and apply patches from `src/<engine>-worklet/patches/` where needed.

```bash
pnpm install

bash scripts/build-rnnoise-worklet.sh   # emcc (standalone wasm)
bash scripts/build-dtln-worklet.sh      # Rust + Emscripten
bash scripts/build-dfn3-worklet.sh      # Rust + wasm-pack
bash scripts/build-stt-assets.sh        # esbuild (parakeet.js, vad-web, ort)
bash scripts/build-livekit-bundle.sh    # esbuild (livekit-client)
bash scripts/fetch-mediapipe-assets.sh  # npm tarball + Google model repo (SHA-256 pinned)

# Verify built engines end-to-end in headless Chromium:
node scripts/smoke-ns-worklet.mjs <rnnoise|dtln|dfn3>
node scripts/smoke-stt-worker.mjs
```

## Releasing a new version

1. Rebuild the affected assets (above) and commit `vendor/`.
2. Bump `lib/discourse_voice_assets/version.rb`, tag, and release the gem.
3. In Discourse: bump the gem version. Nothing else — the plugin references
   the stable filenames and derives the versioned URL at runtime. Renaming or
   removing a vendored file (see the spec's stable-path list) is a breaking
   change needing a coordinated plugin update.

## Development

```bash
bundle install
bundle exec rspec  # vendor tree / manifest integrity
pnpm test:js       # worklet source unit tests (node --test)
```
