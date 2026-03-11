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
  system.primaryUser = "ericssonbudhilaw";

  users.users.ericssonbudhilaw = {
    home = "/Users/ericssonbudhilaw";
    shell = pkgs.fish;
  };

  users.users._dnscrypt-proxy.home = lib.mkForce "/private/var/lib/dnscrypt-proxy";

  nix.enable = false;

  # Cachix binary cache configuration (works with Determinate Nix)
  nix.settings = {
    trusted-users = [
      "ericssonbudhilaw"
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
    hostName = lib.mkDefault "NB-EricssonBudhilaw-Tech";
    computerName = config.networking.hostName;
    knownNetworkServices = ["Wi-Fi" "Ethernet" "USB 10/100/1000 LAN"];
    dns = ["127.0.0.1"];
  };

  services = {
    dnscrypt-proxy.enable = true;
    dnscrypt-proxy.settings = {
      listen_addresses = [ "127.0.0.1:53530" ];
      server_names = [ "doh.tiarap.org" "doh.tiar.app-doh" ];
      require_nolog = true;
      require_dnssec = true;
      require_nofilter = false;
      cache = true;
      cache_size = 4096;
      cache_min_ttl = 2400;
      cache_max_ttl = 86400;
      query_log = {
        file = "/private/var/lib/dnscrypt-proxy/query.log";
        ignored_qtypes = [ "DNSKEY" "NS" ];
      };
    };
  };

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
    persistent-apps = [
      { app = "/System/Applications/Launchpad.app"; }
      { app = "${pkgs.brave-browser}/Applications/Brave Browser.app"; }
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
    AppleShowAllExtensions = true;
    AppleShowAllFiles = true;
    QuitMenuItem = true;
    FXEnableExtensionChangeWarning = false;
    ShowPathbar = true;
    ShowStatusBar = true;
    _FXShowPosixPathInTitle = true;
  };
}
