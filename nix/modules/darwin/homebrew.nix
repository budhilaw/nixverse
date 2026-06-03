{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf;
  brewEnabled = config.homebrew.enable;
in
{
  environment.shellInit =
    mkIf brewEnabled # bash
      ''
        eval "$(${config.homebrew.prefix}/bin/brew shellenv)"
      '';

  # Note: Homebrew installation is now handled automatically by nix-darwin
  # The preUserActivation script has been removed as it's deprecated

  homebrew.enable = true;
  homebrew.brews = [
    "protobuf"
    "kcat"
  ];
  homebrew.onActivation.cleanup = "zap";
  homebrew.global.brewfile = true;

  # Removed masApps as they keep reinstalling on every rebuild
  homebrew.masApps = {
    "Passepartout" = 1433648537;
    "WhatsApp Messenger" = 310633997;
  };

  homebrew.casks = [
    # password managers
    "1password"
    "1password-cli"

    # browsers
    "brave-browser"
    "google-chrome"

    # productivity
    "appcleaner"
    "jordanbaird-ice"
    "logi-options+"
    "raycast"
    "rectangle"
    "shottr"
    "protonvpn"
    "stats"
    "qbittorrent"
    "the-unarchiver"

    # chat
    "discord"
    "telegram"

    # media
    "iina"
    "moonlight"
    "mounty"
    "obs"

    # file system support
    "macfuse"

    # android development
    "android-file-transfer"

    # communication
    "slack"
    "zoom"

    # developer tools
    "cursor"
    "dbeaver-community"
    "iterm2"
    "jetbrains-toolbox"
    "orbstack"
    "postman"
    "claude"
    "codex"

    # research
    "mendeley-reference-manager"

    # fonts
    "font-caskaydia-mono-nerd-font"
  ];

}
