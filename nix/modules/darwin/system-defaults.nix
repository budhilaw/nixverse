# macOS preferences. Everything here is applied as the primary user by
# nix-darwin, including CustomUserPreferences (plain `defaults write`).
{
  system.defaults = {
    dock = {
      autohide = true;
      show-recents = false;
      showhidden = true;
      mru-spaces = false;
      persistent-apps = [
        { app = "/System/Applications/Apps.app"; }
        { app = "/Applications/Brave Browser.app"; }
        { app = "/System/Applications/Calendar.app"; }
        { app = "/System/Applications/Messages.app"; }
        { app = "/System/Applications/Mail.app"; }
        { app = "/System/Applications/Music.app"; }
        { app = "/Applications/iTerm.app"; }
        { app = "/Applications/WhatsApp.app"; }
        { app = "/Applications/Bitwarden.app"; }
        { app = "/System/Applications/System Settings.app"; }
        { app = "/System/Applications/App Store.app"; }
      ];
    };

    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      QuitMenuItem = true;
      FXEnableExtensionChangeWarning = false;
      ShowPathbar = true;
      ShowStatusBar = true;
      _FXShowPosixPathInTitle = true;
    };

    NSGlobalDomain.AppleKeyboardUIMode = 3;

    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = false;
    };

    CustomUserPreferences = {
      # Brave: switch off the bundled extras.
      "com.brave.Browser" = {
        BraveRewardsDisabled = true;
        BraveWalletDisabled = true;
        BraveVPNDisabled = true;
        BraveAIChatEnabled = false;
        IPFSEnabled = false;
        TorDisabled = true;
        SidebarSearchEnabled = false;
        HideSidePanelButton = true;
        ShowFullUrlsInAddressBar = true;
        BraveNewsEnabled = false;
        BraveTalkEnabled = false;
      };
      # iTerm2 top-level keys; the per-profile keys live in the host config.
      "com.googlecode.iterm2" = {
        ShowMarkIndicators = false;
        HideScrollbar = true;
        TerminalMargin = 10;
        TerminalVMargin = 10;
        ClickToSelectCommand = 0;
      };
    };
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = false;
  };
}
