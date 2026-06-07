class Vuvuzela < Formula
  desc "macOS desktop widget for FIFA World Cup 2026 — groups, matches, bracket"
  homepage "https://github.com/bsnkhua/vuvuzela"
  url "https://github.com/bsnkhua/vuvuzela/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "PLACEHOLDER"
  license "MIT"
  head "https://github.com/bsnkhua/vuvuzela.git", branch: "main"

  depends_on :macos
  depends_on macos: :sonoma

  def install
    system "swift", "build", "--disable-sandbox", "-c", "release"

    app = prefix/"Vuvuzela.app"
    (app/"Contents/MacOS").install ".build/release/Vuvuzela"
    (app/"Contents").install "Resources/Info.plist"
    (app/"Contents/Resources").install "Resources/AppIcon.icns"
    system "codesign", "--force", "--sign", "-", app

    (bin/"vuvuzela").write <<~EOS
      #!/bin/bash
      exec open "#{prefix}/Vuvuzela.app"
    EOS
  end

  def caveats
    <<~EOS
      Launch the widget with:
        vuvuzela

      After an upgrade, restart it so the new version runs:
        pkill -f "Vuvuzela.app"; sleep 1; vuvuzela

      Quit it from the menu bar icon ⚽ → Quit Vuvuzela.
      Disable "Launch at login" before uninstalling.
    EOS
  end

  test do
    assert_path_exists prefix/"Vuvuzela.app/Contents/MacOS/Vuvuzela"
    system "/usr/bin/plutil", "-lint", prefix/"Vuvuzela.app/Contents/Info.plist"
  end
end
