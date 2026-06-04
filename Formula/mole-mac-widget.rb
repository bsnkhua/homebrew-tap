class MoleMacWidget < Formula
  desc "Native macOS desktop widget with live system metrics"
  homepage "https://github.com/bsnkhua/mole-mac-widget"
  url "https://github.com/bsnkhua/mole-mac-widget/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "5f991d558d8ba652d18b534036767025c4984491dba33e4b1c0aa7cb4ec93ab2"
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
    EOS
  end

  test do
    assert_path_exists prefix/"Mole Widget.app/Contents/MacOS/MoleWidget"
    system "/usr/bin/plutil", "-lint", prefix/"Mole Widget.app/Contents/Info.plist"
  end
end
