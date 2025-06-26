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

  # Set primary user for nix-darwin options that require it
  system.primaryUser = "budhilaw";

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
      # System apps 
      { app = "/System/Applications/Launchpad.app"; }
      { app = "${pkgs.google-chrome}/Applications/Google Chrome.app"; }
      { app = "/System/Applications/Calendar.app"; }
      { app = "/System/Applications/Messages.app"; }
      { app = "/System/Applications/Mail.app"; }
      { app = "/System/Applications/Music.app"; }
      { app = "${pkgs.iterm2}/Applications/iTerm.app"; }
      { app = "/Applications/Cursor.app"; }
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