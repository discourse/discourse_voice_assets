# frozen_string_literal: true

RSpec.describe DiscourseVoiceAssets do
  it "has a version number" do
    expect(DiscourseVoiceAssets::VERSION).not_to be_nil
  end

  it "vendors exactly the declared asset directories" do
    on_disk =
      Dir.children(described_class.vendor_path).select do |c|
        File.directory?(described_class.vendor_path(c))
      end
    expect(on_disk.sort).to eq(described_class::DIRECTORIES)
  end

  # The consuming plugin references these stable paths directly; renaming or
  # dropping any of them is a breaking change requiring a coordinated bump.
  %w[
    dfn3/dfn3-worklet.js
    dfn3/dfn3.wasm
    dfn3/dfn3-model.bin
    dtln/dtln-worklet.js
    dtln/dtln.wasm
    rnnoise/rnnoise-worklet.js
    rnnoise/rnnoise.wasm
    stt/subtitles-worker.js
    stt/vad.js
    stt/ort/ort-wasm-simd-threaded.jsep.js
    stt/ort/ort-wasm-simd-threaded.jsep.wasm
    stt/vad/silero_vad_v5.onnx
    stt/vad/silero_vad_legacy.onnx
    stt/vad/vad.worklet.bundle.min.js
    livekit/livekit-client.js
    mediapipe/vision_bundle.js
    mediapipe/selfie_segmenter.tflite
    mediapipe/wasm/vision_wasm_internal.js
    mediapipe/wasm/vision_wasm_internal.wasm
    mediapipe/wasm/vision_wasm_nosimd_internal.js
    mediapipe/wasm/vision_wasm_nosimd_internal.wasm
  ].each do |file|
    it "vendors #{file}" do
      expect(File).to exist(described_class.vendor_path(file))
    end
  end
end
