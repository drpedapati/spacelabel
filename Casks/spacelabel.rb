cask "spacelabel" do
  version "0.1.0"
  sha256 "0a1aee0cc83b6892ef459f0429f7c29a89068c01266d2e1e947479a16e9e678c"

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
