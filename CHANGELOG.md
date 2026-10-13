## [Unreleased]

## [0.2.0] - 2026-10-09

- Speech-to-text runs on onnxruntime-web 1.30's native WebGPU execution provider, which can run quantized (2-bit and 4-bit MatMulNBits) Parakeet encoders such as Parakeet Ultra and Redux.
- **Breaking:** the ORT runtime pair is now `stt/ort/ort-wasm-simd-threaded.asyncify.{js,wasm}` (was `.jsep`).
- **Breaking:** the subtitles worker no longer has a default model or fp16/fp32 encoder selection. `init` requires `modelBaseUrl`, pointing at a directory with `encoder-model.onnx` (single file), `decoder_joint-model.int8.onnx` and `vocab.txt`. `encoderQuant`/`decoderQuant` are ignored.
- The worker keeps only the current model in its Cache API store, evicting files from any other model or mirror (including old multi-GB fp32 copies).

## [0.1.0] - 2026-08-31

- Initial release: assets extracted from the resenha plugin (noise-suppression engines, speech-to-text runtime, MediaPipe segmentation, livekit-client bundle) plus their build toolchain.
