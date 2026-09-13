{
  lib,
  config,
  pkgs,
  ...
}:

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
