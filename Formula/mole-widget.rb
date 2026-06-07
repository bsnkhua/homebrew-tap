class MoleWidget < Formula
  desc "Native macOS desktop widget with live system metrics"
  homepage "https://github.com/bsnkhua/mole-widget"
  url "https://github.com/bsnkhua/mole-widget/archive/refs/tags/v0.5.3.tar.gz"
  sha256 "e1512737d17c508c128b1922225f4719c68903bc7308b09bb62e7fe08c8ae718"
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

      After an upgrade, restart it so the new version actually runs:
        pkill -f "Mole Widget.app"; sleep 1; mole-widget

      Quit it from the menu bar icon -> Quit Mole Widget.
      Disable "Launch at login" before uninstalling.
    EOS
  end

  test do
    assert_path_exists prefix/"Mole Widget.app/Contents/MacOS/MoleWidget"
    system "/usr/bin/plutil", "-lint", prefix/"Mole Widget.app/Contents/Info.plist"
  end
end
