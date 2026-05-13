# Template for the Homebrew cask file.
#
# Copy this file into the pulikkalgokul/homebrew-tap repo as Casks/neonfocus.rb
# and update `version` + `sha256` after each release (the release.sh script
# prints both values when it finishes).
cask "neonfocus" do
  version "0.1.0"
  sha256 "REPLACE_WITH_SHA256_FROM_RELEASE_SCRIPT"

  url "https://github.com/pulikkalgokul/NeonFocus/releases/download/v#{version}/NeonFocus-#{version}.zip"
  name "NeonFocus"
  desc "Neon halo overlay around the focused terminal window"
  homepage "https://github.com/pulikkalgokul/NeonFocus"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :sonoma"

  app "NeonFocus.app"

  zap trash: [
    "~/Library/Preferences/com.gokul.NeonFocus.plist",
  ]

  caveats <<~EOS
    NeonFocus needs Accessibility permission to detect the focused
    terminal window. On first launch, grant it in:

      System Settings → Privacy & Security → Accessibility

    Then re-launch NeonFocus from /Applications.
  EOS
end
