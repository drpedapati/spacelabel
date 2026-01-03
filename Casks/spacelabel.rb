cask "spacelabel" do
  version "0.1.0"
  sha256 "7de1a09a277f0cb9ddad05e0a7e1cbdd7a98f05fc205f7096f987f0bf6b8660c"

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
