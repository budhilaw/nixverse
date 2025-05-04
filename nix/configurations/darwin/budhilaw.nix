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

  users.users.budhilaw = {
    home = "/Users/budhilaw";
    shell = pkgs.fish;
  };

  users.users._dnscrypt-proxy.home = lib.mkForce "/private/var/lib/dnscrypt-proxy";

  # --- see: nix/nixosModules/nix.nix
  # --- disabled because i use determinate nix installer
  # nix-settings = {
  #   enable = true;
  #   use = "full";
  #   inputs-to-registry = true;
  # };

  nix.enable = false;

  # --- nix-darwin
  homebrew.enable = true;

  networking = {
    hostName = lib.mkDefault "budhilaw";
    computerName = config.networking.hostName;
    knownNetworkServices = ["Wi-Fi" "Ethernet" "USB 10/100/1000 LAN"];
  };

  services = {
    dnscrypt-proxy.enable = true;
    dnscrypt-proxy.settings.listen_addresses = [ "127.0.0.1:5353" ];
  };

  # --- dock configuration
  system.defaults.dock = {
    autohide = true;
    show-recents = false;
    showhidden = true;
    mru-spaces = false;
    # Configure apps that should appear in the Dock
    persistent-apps = [
      # System apps 
      { app = "/System/Applications/Launchpad.app"; }
      { app = "/Applications/Brave Browser.app"; }
      { app = "/System/Applications/Calendar.app"; }
      { app = "/System/Applications/Messages.app"; }
      { app = "/System/Applications/Mail.app"; }
      { app = "/System/Applications/Music.app"; }
      { app = "${pkgs.obsidian}/Applications/Obsidian.app"; }
      { app = "${pkgs.iterm2}/Applications/iTerm.app"; }
      { app = "/Applications/Cursor.app"; }
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