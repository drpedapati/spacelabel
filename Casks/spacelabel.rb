cask "spacelabel" do
  version "0.1.0"
  sha256 "8868732873fa84784ab3697fc293bb6e5f5b2efd195c5f2b86971a20f473a835"

  url "https://github.com/drpedapati/spacelabel/releases/download/v#{version}/SpaceLabel.app.zip"
  name "SpaceLabel"
  desc "Know where you are. Name your macOS Spaces."
  homepage "https://github.com/drpedapati/spacelabel"

  depends_on macos: ">= :monterey"

  app "SpaceLabel.app"

  zap trash: [
    "~/Library/Preferences/com.drpedapati.spacelabel.plist",
  ]
end
