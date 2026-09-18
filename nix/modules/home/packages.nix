{
  lib,
  config,
  pkgs,
  ...
}:

let
  pnpmHome =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "${config.home.homeDirectory}/Library/pnpm"
    else
      "${config.home.homeDirectory}/.local/share/pnpm";
in
{
  options.within.dev.enable = lib.mkEnableOption "developer toolchain and cloud CLIs" // {
    default = true;
  };

  config = {
    programs.home-manager.enable = true;

    programs.bat = {
      enable = true;
      config = {
        style = "plain";
        theme = "TwoDark";
      };
    };

    programs.direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
    };

    # pnpm is the only global JS package manager. Its content-addressable
    # store under PNPM_HOME is shared by every project and by `pnpm add -g`,
    # so nothing gets duplicated the way `npm i -g` / per-project npm
    # node_modules do. Same shape as home-manager's programs.pnpm, which is
    # newer than the locked home-manager input.
    home.sessionVariables.PNPM_HOME = pnpmHome;
    home.sessionPath = [ "${pnpmHome}/bin" ];

    programs.btop = {
      enable = true;
      settings = {
        vim_keys = true;
        show_battery = false;
      };
    };

    home.packages =
      with pkgs;
      [
        # everyday CLI
        lsd
        eza
        htop
        tldr
        jq
        fd
        wget
        curl
        fastfetch
        git
        tmux
        starship
        gnupg
        openssl
        cachix
      ]
      ++ lib.optionals config.within.dev.enable [
        # stable branch so it matches the node dev shells
        stable.pnpm
        pkg-config
        kubectl
        (google-cloud-sdk.withExtraComponents [ google-cloud-sdk.components.gke-gcloud-auth-plugin ])
        mkcert
        ffmpeg
        android-tools
      ]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [
        vscode
        docker # CLI for OrbStack
        cloudflared
        mas
        m-cli
        xcode-install
        pinentry_mac
      ];
  };
}
