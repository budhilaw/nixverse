# GUI apps and a few CLIs that are better served by Homebrew than by nixpkgs.
{ config, lib, ... }:

{
  homebrew = {
    enable = true;
    global.brewfile = true;
    onActivation.cleanup = "zap";
    # Homebrew 5 requires --force-cleanup alongside --cleanup --zap.
    onActivation.extraFlags = [ "--force-cleanup" ];

    brews = [
      "protobuf"
      "kcat"
      "bitwarden-cli"
      # Tailscale CLI + tailscaled. The formula (not the App Store app) because
      # Headscale needs a custom --login-server. Enroll with:
      #   sudo tailscaled install-system-daemon
      #   sudo tailscale up --login-server https://headscale.budhilaw.com
      "tailscale"
    ];

    masApps = {
      "Passepartout" = 1433648537;
      "WhatsApp Messenger" = 310633997;
      "Bitwarden" = 1352778147;
    };

    casks = [
      # browsers
      # brave-browser is pinned to 1.91.168 by hand (.pkg, auto-update off)
      # because 1.91.171+ breaks Bitwarden inline autofill:
      # https://github.com/brave/brave-browser/issues/56255
      "brave-browser"
      "google-chrome"

      # productivity
      "vorssaint"
      "thaw@beta"
      "shottr"
      "protonvpn"
      # "qbittorrent"
      "the-unarchiver"
      "cap"

      # chat
      "discord"
      "telegram"
      "slack"
      "zoom"

      # media
      "iina"
      "moonlight"
      "mounty"
      "obs"

      # android
      "android-file-transfer"

      # developer tools
      "jetbrains-toolbox"
      "dbeaver-community"
      "iterm2"
      "orbstack"
      "postman"
      "claude"
      "codex"

      # fonts
      "font-caskaydia-mono-nerd-font"
    ];
  };

  environment.shellInit = lib.mkIf config.homebrew.enable ''
    eval "$(${config.homebrew.prefix}/bin/brew shellenv)"
  '';
}
