class MoleMacWidget < Formula
  desc "Native macOS desktop widget with live system metrics"
  homepage "https://github.com/bsnkhua/mole-mac-widget"
  url "https://github.com/bsnkhua/mole-mac-widget/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "e186aa2d9fc6d3ea1fb15b053204f1ecf9f5a26db69d92e91543cf5b4f480377"
  license "MIT"
  head "https://github.com/bsnkhua/mole-mac-widget.git", branch: "main"

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

      Quit it from the menu bar icon (chart symbol) -> Quit mole-widget.

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
