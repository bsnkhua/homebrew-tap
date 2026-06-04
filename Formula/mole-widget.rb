class MoleWidget < Formula
  desc "Native macOS desktop widget with live system metrics"
  homepage "https://github.com/bsnkhua/mole-widget"
  url "https://github.com/bsnkhua/mole-widget/archive/refs/tags/v0.4.0.tar.gz"
  sha256 "979743f17c1ea6eb16b8b25be4980b041b95e7cefca4f58d4dd27c573c5716b5"
  license "MIT"
  head "https://github.com/bsnkhua/mole-widget.git", branch: "main"

  depends_on :macos
  depends_on macos: :sonoma

  def install
    # Building from source on the user's machine keeps Gatekeeper happy:
    # locally built apps don't get the quarantine attribute.
    system "swift", "build", "--disable-sandbox", "-c", "release"

    app = prefix/"Mole Widget.app"
    (app/"Contents/MacOS").install ".build/release/MoleWidget"
    (app/"Contents").install "Resources/Info.plist"
    (app/"Contents/Resources").install "Resources/AppIcon.icns"
    system "codesign", "--force", "--sign", "-", app

    (bin/"mole-widget").write <<~EOS
      #!/bin/bash
      exec open "#{prefix}/Mole Widget.app"
    EOS
  end

  def caveats
    <<~EOS
      Launch the widget with:
        mole-widget

      Quit it from the menu bar icon (chart symbol) -> Quit Mole Widget.

      If you enabled "Launch at login", re-toggle it after upgrading
      (the login item points to the versioned install path), and
      disable it before uninstalling.
    EOS
  end

  test do
    assert_path_exists prefix/"Mole Widget.app/Contents/MacOS/MoleWidget"
    system "/usr/bin/plutil", "-lint", prefix/"Mole Widget.app/Contents/Info.plist"
  end
end
