# frozen_string_literal: true

require_relative "discourse_voice_assets/version"

module DiscourseVoiceAssets
  class Error < StandardError
  end

  # Asset directories served by the consuming plugin under its public
  # javascripts dir. Each maps 1:1 to a directory under vendor/.
  DIRECTORIES = %w[dfn3 dtln livekit mediapipe rnnoise stt].freeze

  def self.gem_root
    @gem_root ||= File.expand_path("../..", __FILE__)
  end

  # Absolute path to a vendored asset (or asset directory when called with
  # no arguments beyond the directory name).
  def self.vendor_path(*segments)
    File.join(gem_root, "vendor", *segments)
  end

  # Absolute path to a generated JS manifest module. Manifests are emitted
  # by the build scripts alongside the assets they describe; the consuming
  # plugin commits verbatim copies (its build graph cannot import from the
  # gem) and verifies them against these on every test run.
  def self.manifest_path(name)
    File.join(gem_root, "manifests", name)
  end
end
