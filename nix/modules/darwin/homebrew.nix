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
    "bitwarden-cli"
    # Tailscale CLI + tailscaled daemon. Using the formula (not the App Store
    # app) because Headscale needs a custom --login-server, which the sandboxed
    # GUI app makes awkward. Enroll: sudo tailscaled install-system-daemon then
    # sudo tailscale up --login-server https://headscale.budhilaw.com
    "tailscale"
  ];
  homebrew.onActivation.cleanup = "zap";
  # Homebrew 5.x requires --cleanup to be paired with --force-cleanup (or
  # --force / $HOMEBREW_ASK); nix-darwin only emits "--cleanup --zap", so
  # activation aborts without this. See `brew bundle --help`.
  homebrew.onActivation.extraFlags = [ "--force-cleanup" ];
  homebrew.global.brewfile = true;

  # Removed masApps as they keep reinstalling on every rebuild
  homebrew.masApps = {
    "Passepartout" = 1433648537;
    "WhatsApp Messenger" = 310633997;
    "Bitwarden" = 1352778147;
  };

  homebrew.casks = [
    # password managers
    # "1password"
    # "1password-cli"
    # "bitwarden"
    "steam"

    # browsers
    # brave-browser pinned to 1.91.168 manually (installed via .pkg, auto-update
    # blocked) because 1.91.171+ breaks Bitwarden inline autofill — see
    # https://github.com/brave/brave-browser/issues/56255. Re-enable once fixed.
    "brave-browser"
    "google-chrome"

    # productivity
    "appcleaner"
    "thaw@beta"
    "logi-options+"
    "raycast"
    "rectangle"
    "shottr"
    "protonvpn"
    # "stats"
    "qbittorrent"
    "the-unarchiver"
    "cap"

    # chat
    "discord"
    "telegram"

    # media
    "iina"
    "moonlight"
    "mounty"
    "obs"
    "seadrive"
    "seafile-client"

    # file system support
    "macfuse"

    # android development
    "android-file-transfer"

    # communication
    "slack"
    "zoom"

    # developer tools
    # "cursor"
    "dbeaver-community"
    "iterm2"
    "jetbrains-toolbox"
    "orbstack"
    "postman"
    "claude"
    "codex"
    "antigravity"

    # research
    "mendeley-reference-manager"

    # fonts
    "font-caskaydia-mono-nerd-font"
  ];

}
