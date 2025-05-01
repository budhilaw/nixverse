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

  system.activationScripts.preUserActivation.text =
    mkIf brewEnabled # bash
      ''
        if [ ! -f ${config.homebrew.brewPrefix}/brew ]; then
          ${pkgs.bash}/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
      '';

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
    "1password"
    "1password-cli"
    "pritunl"
    "logi-options+"
    "jetbrains-toolbox"

    "discord"
    "mist"
    "moonlight"
    "mounty"
    "cloudflare-warp"
    "slack"
  ];

}
