# frozen_string_literal: true

RSpec.describe DiscourseVoiceAssets do
  it "has a version number" do
    expect(DiscourseVoiceAssets::VERSION).not_to be_nil
  end

  it "vendors exactly the declared asset directories" do
    on_disk = Dir.children(described_class.vendor_path).select { |c|
      File.directory?(described_class.vendor_path(c))
    }
    expect(on_disk.sort).to eq(described_class::DIRECTORIES)
  end

  # The manifests are what the consuming plugin imports (via committed
  # copies); every file they name must exist in vendor/.
  describe "manifests" do
    def manifest_files(name)
      File
        .read(described_class.manifest_path(name))
        .scan(/^export const \w+ = "([^"]+)";$/)
        .flatten
    end

    %w[dfn3 dtln rnnoise].each do |engine|
      it "names only existing files for #{engine}" do
        files = manifest_files("#{engine}.js")
        expect(files).not_to be_empty
        files.each do |file|
          expect(File).to exist(described_class.vendor_path(file)),
          "#{engine}.js references missing vendor file: #{file}"
        end
      end
    end

    it "names only existing files for stt" do
      files = manifest_files("stt-assets.js")
      expect(files).not_to be_empty
      files.each do |file|
        path = described_class.vendor_path("stt", file)
        if file.end_with?("/")
          expect(File).to be_directory(path), "stt-assets.js references missing dir: #{file}"
        else
          expect(File).to exist(path), "stt-assets.js references missing vendor file: #{file}"
        end
      end
    end
  end

  it "vendors the self-contained livekit-client bundle" do
    expect(File).to exist(described_class.vendor_path("livekit", "livekit-client.js"))
  end

  it "vendors the MediaPipe runtime and segmentation model" do
    %w[
      vision_bundle.js
      selfie_segmenter.tflite
      wasm/vision_wasm_internal.js
      wasm/vision_wasm_internal.wasm
      wasm/vision_wasm_nosimd_internal.js
      wasm/vision_wasm_nosimd_internal.wasm
    ].each { |file| expect(File).to exist(described_class.vendor_path("mediapipe", file)) }
  end
end
