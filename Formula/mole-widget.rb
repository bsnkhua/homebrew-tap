class MoleWidget < Formula
  desc "Native macOS desktop widget with live system metrics"
  homepage "https://github.com/bsnkhua/mole-widget"
  url "https://github.com/bsnkhua/mole-widget/archive/refs/tags/v0.7.0.tar.gz"
  sha256 "09589c70165432d84bd3c82d50d849d97149abbf26929e382b3db3a48bd73897"
  license "MIT"
  head "https://github.com/bsnkhua/mole-widget.git", branch: "main"

  depends_on macos: :sonoma

  def install
    # Building from source on the user's machine keeps Gatekeeper happy:
    # locally built apps don't get the quarantine attribute.
    system "swift", "build", "--disable-sandbox", "-c", "release"

    app = prefix/"Mole Widget.app"
    (app/"Contents/MacOS").mkpath
    (app/"Contents/Resources").mkpath
    (app/"Contents/Frameworks").mkpath

    cp ".build/release/MoleWidget", app/"Contents/MacOS/MoleWidget"
    cp_r ".build/release/Sparkle.framework", app/"Contents/Frameworks/Sparkle.framework"
    MachO::Tools.add_rpath(app/"Contents/MacOS/MoleWidget", "@executable_path/../Frameworks")
    (app/"Contents").install "Resources/Info.plist"
    (app/"Contents/Resources").install "Resources/AppIcon.icns"

    (bin/"mole-widget").write <<~EOS
      #!/bin/bash
      exec open "#{prefix}/Mole Widget.app"
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
    app = prefix/"Mole Widget.app"
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
    system "codesign", "--verify", "--deep", "--strict", prefix/"Mole Widget.app"
  end
end
