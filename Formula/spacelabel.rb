class Spacelabel < Formula
  desc "Floating overlay for naming macOS Spaces"
  homepage "https://github.com/drpedapati/spacelabel"
  url "https://github.com/drpedapati/spacelabel/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license "MIT"

  depends_on :macos
  depends_on xcode: ["14.0", :build]

  def install
    system "make"
    prefix.install "SpaceLabel.app"
  end

  def caveats
    <<~EOS
      SpaceLabel.app has been installed to:
        #{prefix}/SpaceLabel.app

      To add to Applications folder:
        ln -sf #{prefix}/SpaceLabel.app /Applications/SpaceLabel.app

      To start automatically at login, add SpaceLabel to:
        System Preferences > Users & Groups > Login Items
    EOS
  end

  test do
    assert_predicate prefix/"SpaceLabel.app/Contents/MacOS/SpaceLabel", :exist?
  end
end
