class Vuvuzela < Formula
  desc "macOS desktop widget for FIFA World Cup 2026 — groups, matches, bracket"
  homepage "https://github.com/bsnkhua/vuvuzela"
  url "https://github.com/bsnkhua/vuvuzela/archive/refs/tags/v1.0.4.tar.gz"
  sha256 "8a727bcb9aaa08fd0c9e8940bf924dde10cbaa131019bf66e9be53bffd2d0798"
  license "MIT"
  head "https://github.com/bsnkhua/vuvuzela.git", branch: "main"

  depends_on :macos
  depends_on macos: :sonoma

  def install
    system "swift", "build", "--disable-sandbox", "-c", "release"

    app = prefix/"Vuvuzela.app"
    (app/"Contents/MacOS").mkpath
    (app/"Contents/Resources").mkpath
    (app/"Contents/Frameworks").mkpath

    cp ".build/release/Vuvuzela", app/"Contents/MacOS/Vuvuzela"
    cp_r ".build/release/Sparkle.framework", app/"Contents/Frameworks/Sparkle.framework"
    system "install_name_tool", "-add_rpath", "@executable_path/../Frameworks",
           app/"Contents/MacOS/Vuvuzela"
    (app/"Contents").install "Resources/Info.plist"
    (app/"Contents/Resources").install "Resources/AppIcon.icns"
    (app/"Contents/Resources").install "Resources/vuvuzela-menubar.png"
    system "codesign", "--force", "--sign", "-", app/"Contents/Frameworks/Sparkle.framework"
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

      Quit from the menu bar icon → Quit Vuvuzela.
      Disable "Launch at login" before uninstalling.
    EOS
  end

  test do
    assert_path_exists prefix/"Vuvuzela.app/Contents/MacOS/Vuvuzela"
    assert_path_exists prefix/"Vuvuzela.app/Contents/Frameworks/Sparkle.framework"
    system "/usr/bin/plutil", "-lint", prefix/"Vuvuzela.app/Contents/Info.plist"
  end
end
