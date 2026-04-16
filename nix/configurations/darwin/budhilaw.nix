{
  lib,
  pkgs,
  ezModules,
  crossModules,
  config,
  ...
}:

{
  imports = lib.attrValues (ezModules // crossModules);

  system.stateVersion = 4;
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Suppress "options.json without proper context" warning from nix-darwin docs generation
  documentation.enable = false;

  # Set primary user for nix-darwin options that require it
  system.primaryUser = "budhilaw";

  users.users.budhilaw = {
    home = "/Users/budhilaw";
    shell = pkgs.fish;
  };

  # Set fish as default shell for budhilaw
  system.activationScripts.postActivation.text = ''
    # Change default shell to fish if not already set
    currentShell=$(dscl . -read /Users/budhilaw UserShell | awk '{print $2}')
    fishPath="/run/current-system/sw/bin/fish"
    if [ "$currentShell" != "$fishPath" ]; then
      chsh -s "$fishPath" budhilaw
    fi

    # Configure iTerm2 default profile
    itermPlist="/Users/budhilaw/Library/Preferences/com.googlecode.iterm2.plist"
    if [ -f "$itermPlist" ]; then
      sudo -u budhilaw defaults write com.googlecode.iterm2 "ShowMarkIndicators" -bool false
      sudo -u budhilaw defaults write com.googlecode.iterm2 "HideScrollbar" -bool true
      sudo -u budhilaw defaults write com.googlecode.iterm2 "TerminalMargin" -int 10
      sudo -u budhilaw defaults write com.googlecode.iterm2 "TerminalVMargin" -int 10
      sudo -u budhilaw defaults write com.googlecode.iterm2 "ClickToSelectCommand" -int 0
      # Window: 110x35, No Title Bar (12), transparency + blur
      /usr/libexec/PlistBuddy \
        -c "Set ':New Bookmarks:0:Columns' 110" \
        -c "Set ':New Bookmarks:0:Rows' 35" \
        -c "Set ':New Bookmarks:0:Character Encoding' 4" \
        -c "Set ':New Bookmarks:0:Normal Font' 'CaskaydiaMonoNF-Regular 14'" \
        -c "Set ':New Bookmarks:0:Non Ascii Font' 'CaskaydiaMonoNF-Regular 14'" \
        -c "Set ':New Bookmarks:0:Window Type' 12" \
        -c "Set ':New Bookmarks:0:Transparency' 0.15" \
        -c "Set ':New Bookmarks:0:Blur' 1" \
        -c "Set ':New Bookmarks:0:Blur Radius' 5" \
        "$itermPlist" 2>/dev/null || true
      # Locale
      /usr/libexec/PlistBuddy -c "Delete ':New Bookmarks:0:Set Local Environment Vars'" "$itermPlist" 2>/dev/null || true
      /usr/libexec/PlistBuddy -c "Add ':New Bookmarks:0:Set Local Environment Vars' integer 2" "$itermPlist" 2>/dev/null || true
      /usr/libexec/PlistBuddy -c "Delete ':New Bookmarks:0:Custom Locale'" "$itermPlist" 2>/dev/null || true
      /usr/libexec/PlistBuddy -c "Add ':New Bookmarks:0:Custom Locale' string 'en_US.UTF-8'" "$itermPlist" 2>/dev/null || true
      # Disable mark indicators per-profile
      /usr/libexec/PlistBuddy -c "Delete ':New Bookmarks:0:Show Mark Indicators'" "$itermPlist" 2>/dev/null || true
      /usr/libexec/PlistBuddy -c "Add ':New Bookmarks:0:Show Mark Indicators' bool false" "$itermPlist" 2>/dev/null || true
      # Natural Text Editing keybindings
      /usr/libexec/PlistBuddy -c "Delete ':New Bookmarks:0:Keyboard Map'" "$itermPlist" 2>/dev/null || true
      /usr/libexec/PlistBuddy \
        -c "Add ':New Bookmarks:0:Keyboard Map' dict" \
        -c "Add ':New Bookmarks:0:Keyboard Map:0x7f-0x80000' dict" \
        -c "Add ':New Bookmarks:0:Keyboard Map:0x7f-0x80000:Action' integer 11" \
        -c "Add ':New Bookmarks:0:Keyboard Map:0x7f-0x80000:Text' string '0x1b 0x7f'" \
        -c "Add ':New Bookmarks:0:Keyboard Map:0x7f-0x100000' dict" \
        -c "Add ':New Bookmarks:0:Keyboard Map:0x7f-0x100000:Action' integer 11" \
        -c "Add ':New Bookmarks:0:Keyboard Map:0x7f-0x100000:Text' string '0x15'" \
        -c "Add ':New Bookmarks:0:Keyboard Map:0xf702-0x280000' dict" \
        -c "Add ':New Bookmarks:0:Keyboard Map:0xf702-0x280000:Action' integer 10" \
        -c "Add ':New Bookmarks:0:Keyboard Map:0xf702-0x280000:Text' string 'b'" \
        -c "Add ':New Bookmarks:0:Keyboard Map:0xf702-0x300000' dict" \
        -c "Add ':New Bookmarks:0:Keyboard Map:0xf702-0x300000:Action' integer 11" \
        -c "Add ':New Bookmarks:0:Keyboard Map:0xf702-0x300000:Text' string '0x1'" \
        -c "Add ':New Bookmarks:0:Keyboard Map:0xf703-0x280000' dict" \
        -c "Add ':New Bookmarks:0:Keyboard Map:0xf703-0x280000:Action' integer 10" \
        -c "Add ':New Bookmarks:0:Keyboard Map:0xf703-0x280000:Text' string 'f'" \
        -c "Add ':New Bookmarks:0:Keyboard Map:0xf703-0x300000' dict" \
        -c "Add ':New Bookmarks:0:Keyboard Map:0xf703-0x300000:Action' integer 11" \
        -c "Add ':New Bookmarks:0:Keyboard Map:0xf703-0x300000:Text' string '0x5'" \
        -c "Add ':New Bookmarks:0:Keyboard Map:0xf728-0x0' dict" \
        -c "Add ':New Bookmarks:0:Keyboard Map:0xf728-0x0:Action' integer 11" \
        -c "Add ':New Bookmarks:0:Keyboard Map:0xf728-0x0:Text' string '0x4'" \
        -c "Add ':New Bookmarks:0:Keyboard Map:0xf728-0x80000' dict" \
        -c "Add ':New Bookmarks:0:Keyboard Map:0xf728-0x80000:Action' integer 10" \
        -c "Add ':New Bookmarks:0:Keyboard Map:0xf728-0x80000:Text' string 'd'" \
        "$itermPlist" 2>/dev/null || true
    fi

    # --- Brave browser: disable all bloatware
    defaults write com.brave.Browser BraveRewardsDisabled -bool true
    defaults write com.brave.Browser BraveWalletDisabled -bool true
    defaults write com.brave.Browser BraveVPNDisabled -bool true
    defaults write com.brave.Browser BraveAIChatEnabled -bool false
    defaults write com.brave.Browser IPFSEnabled -bool false
    defaults write com.brave.Browser TorDisabled -bool true
    defaults write com.brave.Browser SidebarSearchEnabled -bool false
    defaults write com.brave.Browser HideSidePanelButton -bool true
    defaults write com.brave.Browser ShowFullUrlsInAddressBar -bool true
    defaults write com.brave.Browser BraveNewsEnabled -bool false
    defaults write com.brave.Browser BraveTalkEnabled -bool false
  '';

  users.users._dnscrypt-proxy.home = lib.mkForce "/private/var/lib/dnscrypt-proxy";

  # --- see: nix/nixosModules/nix.nix
  # --- disabled because i use determinate nix installer
  # nix-settings = {
  #   enable = true;
  #   use = "full";
  #   inputs-to-registry = true;
  # };

  # Set system locale
  environment.variables = {
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
  };

  nix.enable = false;

  # Cachix binary cache configuration (works with Determinate Nix)
  nix.settings = {
    trusted-users = [
      "budhilaw"
      "root"
    ];
    substituters = [
      "https://cache.nixos.org"
      "https://budhilaw.cachix.org"
      "https://nix-community.cachix.org"
      "https://devenv.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "budhilaw.cachix.org-1:Fbyz4CIpkeY0n6XkK3v2lznxqAvA+vGBJGHBahaI53A="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };

  # --- nix-darwin
  homebrew.enable = true;

  networking = {
    hostName = lib.mkDefault "budhilaw";
    computerName = config.networking.hostName;
    knownNetworkServices = ["Wi-Fi" "Ethernet" "USB 10/100/1000 LAN"];
    dns = ["127.0.0.1"];  # Now using stable dnsmasq forwarder
  };

  services = {
    dnscrypt-proxy.enable = true;
    dnscrypt-proxy.settings = {
      listen_addresses = [ "127.0.0.1:53530" ];
      # Use Cloudflare and Quad9 as default resolvers
      server_names = [ "doh.tiarap.org" "doh.tiar.app-doh" ];
      # Enable blocking of ads/malware/phishing
      require_nolog = true;
      require_dnssec = true;
      require_nofilter = false;
      # Cache settings
      cache = true;
      cache_size = 4096;
      cache_min_ttl = 2400;
      cache_max_ttl = 86400;
      # Enable query logging for debugging (can be disabled later)
      query_log = {
        file = "/private/var/lib/dnscrypt-proxy/query.log";
        ignored_qtypes = [ "DNSKEY" "NS" ];
      };
    };
  };

  # DNS forwarder using dnsmasq for more robust handling
  launchd.daemons.dns-forwarder = {
    script = ''
      exec ${pkgs.dnsmasq}/bin/dnsmasq \
        --keep-in-foreground \
        --no-daemon \
        --no-resolv \
        --bind-interfaces \
        --listen-address=127.0.0.1 \
        --port=53 \
        --server=127.0.0.1#53530 \
        --cache-size=1000 \
        --log-facility=- \
        --no-poll
    '';
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
      Label = "org.nixos.dns-forwarder";
    };
  };

  # --- dock configuration
  system.defaults.dock = {
    autohide = true;
    show-recents = false;
    showhidden = true;
    mru-spaces = false;
    # Configure apps that should appear in the Dock
    persistent-apps = [
      { app = "/System/Applications/Apps.app"; }
      { app = "/Applications/Brave Browser.app"; }
      { app = "/System/Applications/Calendar.app"; }
      { app = "/System/Applications/Messages.app"; }
      { app = "/System/Applications/Mail.app"; }
      { app = "/System/Applications/Music.app"; }
      { app = "/Applications/iTerm.app"; }
      { app = "/Applications/WhatsApp.app"; }
      { app = "/System/Applications/System Settings.app"; }
      { app = "/System/Applications/App Store.app"; }
    ];
  };

  # --- Finder configuration
  system.defaults.finder = {
    AppleShowAllExtensions = true;            # Show file extensions
    AppleShowAllFiles = true;                 # Show hidden files
    QuitMenuItem = true;                      # Allow quitting Finder
    FXEnableExtensionChangeWarning = false;   # Don't warn when changing file extension
    ShowPathbar = true;                       # Show path bar
    ShowStatusBar = true;                     # Show status bar
    _FXShowPosixPathInTitle = true;           # Show full path in title
  };
}