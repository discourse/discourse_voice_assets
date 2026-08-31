# frozen_string_literal: true

require_relative "lib/discourse_voice_assets/version"

Gem::Specification.new do |spec|
  spec.name = "discourse_voice_assets"
  spec.version = DiscourseVoiceAssets::VERSION
  spec.authors = ["Rafael Silva"]
  spec.email = ["xfalcox@gmail.com"]

  spec.summary =
    "Prebuilt browser media assets for Discourse voice/video chat: noise-suppression wasm engines, speech-to-text runtime, MediaPipe segmentation, and the LiveKit client bundle"
  spec.description =
    "Vendors the large binary browser assets used by Discourse voice/video chat so they stay out of the main repository: RNNoise, DTLN, and DeepFilterNet3 noise-suppression AudioWorklet bundles (wasm + models), the onnxruntime-web/Silero VAD/parakeet.js speech-to-text runtime, the MediaPipe selfie-segmentation runtime for background blur, and a self-contained livekit-client SDK bundle. Includes the pinned, reproducible build scripts that produce every artifact."
  spec.homepage = "https://github.com/discourse/discourse_voice_assets"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/discourse/discourse_voice_assets/blob/main/CHANGELOG.md"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[spec/ scripts/ src/ .git .github Gemfile package.json pnpm-lock])
    end
  end
  spec.require_paths = %w[lib]

  spec.add_development_dependency "rubocop-discourse", "~> 3.8"
  spec.add_development_dependency "syntax_tree", "~> 6.2.0"
end
