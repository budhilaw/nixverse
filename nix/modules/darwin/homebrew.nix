# GUI apps and a few CLIs that are better served by Homebrew than by nixpkgs.
# This is the base set every Mac gets, and all the office Mac (macbook-pro)
# gets. Personal extras are added in configurations/darwin/macbook-air.nix;
# the lists merge. `zap` uninstalls any cask a host doesn't list, data and all.
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
    ];

    # WhatsApp and Bitwarden are pinned in the dock (system-defaults.nix);
    # Passepartout holds the Amartha OpenVPN profiles.
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

      # chat
      "slack"
      "zoom"

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
