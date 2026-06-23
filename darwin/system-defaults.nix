# Migration of .osx (macOS `defaults write`) to declarative nix-darwin options.
# `killall Finder/Dock` is unnecessary: darwin-rebuild's activation applies these.
# `com.apple.dashboard mcx-disabled` is intentionally dropped (Dashboard is obsolete).
{ ... }:
{
  system.defaults = {
    finder = {
      # Show hidden files
      AppleShowAllFiles = true;
      # Show full POSIX path in the window title
      _FXShowPosixPathInTitle = true;
    };

    dock = {
      # Speed up Mission Control animation
      expose-animation-duration = 0.15;
      # Show hidden apps translucently in the Dock
      showhidden = true;
    };

    NSGlobalDomain = {
      # Always expand the save dialog
      NSNavPanelExpandedStateForSaveMode = true;
      # Faster key repeat
      InitialKeyRepeat = 12;
      KeyRepeat = 1;
    };

    # Settings without a dedicated nix-darwin option go through the generic
    # escape hatch (writes to the named preference domain verbatim).
    CustomUserPreferences = {
      "com.apple.finder" = {
        # Allow text selection in QuickLook (legacy; may be a no-op on current macOS)
        QLEnableTextSelection = true;
      };
      "com.apple.dock" = {
        # Disable the spaces switch animation
        "workspaces-swoosh-animation-off" = true;
      };
      ".GlobalPreferences" = {
        # Trackpad tracking speed
        "com.apple.trackpad.scaling" = 10.0;
      };
      "com.apple.desktopservices" = {
        # Do not create .DS_Store on network volumes
        DSDontWriteNetworkStores = true;
      };
      "com.apple.CrashReporter" = {
        # Disable the crash report dialog
        DialogType = "none";
      };
    };
  };
}
