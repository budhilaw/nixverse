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
        eval "$(${config.homebrew.brewPrefix}/brew shellenv)"
      '';

  # Note: Homebrew installation is now handled automatically by nix-darwin
  # The preUserActivation script has been removed as it's deprecated

  homebrew.enable = true;
  homebrew.brews = [ ];
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
    
    # productivity
    "logi-options+"

    # chat
    "discord"

    # media
    "moonlight"
    "mounty"

    # vpn
    "cloudflare-warp"

    # communication
    "slack"

    # code
    "cursor"
  ];

}
