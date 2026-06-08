class Vuvuzela < Formula
  desc "macOS desktop widget for FIFA World Cup 2026 — groups, matches, bracket"
  homepage "https://github.com/bsnkhua/vuvuzela"
  url "https://github.com/bsnkhua/vuvuzela/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "6720fb5aacce4a108392258c831773be5e5526f381cc19f9ed7b81a02f77f6a7"
  license "MIT"
  head "https://github.com/bsnkhua/vuvuzela.git", branch: "main"

  depends_on macos: :sonoma

  def install
    system "swift", "build", "--disable-sandbox", "-c", "release"

    app = prefix/"Vuvuzela.app"
    (app/"Contents/MacOS").mkpath
    (app/"Contents/Resources").mkpath
    (app/"Contents/Frameworks").mkpath

    cp ".build/release/Vuvuzela", app/"Contents/MacOS/Vuvuzela"
    cp_r ".build/release/Sparkle.framework", app/"Contents/Frameworks/Sparkle.framework"
    MachO::Tools.add_rpath(app/"Contents/MacOS/Vuvuzela", "@executable_path/../Frameworks")
    (app/"Contents").install "Resources/Info.plist"
    (app/"Contents/Resources").install "Resources/AppIcon.icns"
    (app/"Contents/Resources").install "Resources/vuvuzela-menubar.png"
    (app/"Contents/Resources").install "Resources/goal.caf"
    (app/"Contents/Resources").install "Resources/start.caf"
    (app/"Contents/Resources").install "Resources/finish.caf"

    (bin/"vuvuzela").write <<~EOS
      #!/bin/bash
      exec open "#{prefix}/Vuvuzela.app"
    EOS
  end

  # Sign in post_install, not install: Homebrew re-signs/relocates the keg after
  # the install phase, which would otherwise invalidate the app's seal over
  # Sparkle.framework. Signing last makes the installed bundle verify cleanly.
  # Inside-out order (nested code, then framework, then app) mirrors the release
  # CI; we omit the hardened runtime (`--options runtime`) the CI uses -- it is
  # only needed for the notarized Developer ID build and would trip library
  # validation on these ad-hoc signatures.
  def post_install
    app = prefix/"Vuvuzela.app"
    sparkle = app/"Contents/Frameworks/Sparkle.framework/Versions/B"
    system "codesign", "--force", "--preserve-metadata=entitlements,identifier",
           "--sign", "-", sparkle/"XPCServices/Downloader.xpc"
    system "codesign", "--force", "--preserve-metadata=entitlements,identifier",
           "--sign", "-", sparkle/"XPCServices/Installer.xpc"
    system "codesign", "--force", "--sign", "-", sparkle/"Autoupdate"
    system "codesign", "--force", "--sign", "-", sparkle/"Updater.app"
    system "codesign", "--force", "--sign", "-", app/"Contents/Frameworks/Sparkle.framework"
    system "codesign", "--force", "--sign", "-", app
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
    assert_path_exists prefix/"Vuvuzela.app/Contents/Resources/goal.caf"
    system "/usr/bin/plutil", "-lint", prefix/"Vuvuzela.app/Contents/Info.plist"
    system "codesign", "--verify", "--deep", "--strict", prefix/"Vuvuzela.app"
  end
end
