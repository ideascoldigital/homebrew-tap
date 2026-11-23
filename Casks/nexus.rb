cask "nexus" do
  version "0.3.5"
  sha256 "c412269e79d93b2cad0f2a1f6ef326bd12f69774200d3541e152a64785e0f37a"

  url "https://github.com/ideascoldigital/nexus/releases/download/v#{version}/Nexus_#{version}_aarch64.dmg"
  name "Nexus"
  desc "Local-first AI dev orchestrator"
  homepage "https://github.com/ideascoldigital/nexus"

  livecheck do
    url :url
    strategy :github_latest
  end

  # release-native.yml builds macOS only on the arm64 runner: the sidecar embeds
  # the build host's own node binary, so there is no x86_64 dmg for Intel Macs.
  depends_on arch: :arm64
  depends_on :macos

  app "Nexus.app"

  # The bundle is ad-hoc signed (no Developer ID, not notarized), so Gatekeeper
  # reports it as damaged on first launch unless the quarantine flag goes away.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/Nexus.app"]
  end

  uninstall quit: "com.ideascol.nexux"

  zap trash: [
    "~/.nexux",
    "~/Library/Caches/com.ideascol.nexux",
    "~/Library/HTTPStorages/com.ideascol.nexux",
    "~/Library/Preferences/com.ideascol.nexux.plist",
    "~/Library/Saved Application State/com.ideascol.nexux.savedState",
    "~/Library/WebKit/com.ideascol.nexux",
  ]
end
