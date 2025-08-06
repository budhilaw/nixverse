{ pkgs, ... }:

{
  # Packages with configuration --------------------------------------------------------------- {{{
  programs.home-manager.enable = true;

  programs.nix-index.enable = true;

  # Bat, a substitute for cat.
  # https://github.com/sharkdp/bat
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.bat.enable
  programs.bat.enable = true;
  programs.bat.config = {
    style = "plain";
    theme = "TwoDark";
  };
  # Direnv, load and unload environment variables depending on the current directory.

  # https://direnv.net
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.direnv.enable
  programs.direnv.enable = true;
  programs.direnv.silent = true;
  programs.direnv.nix-direnv.enable = true;

  # Htop
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.btop.enable
  programs.btop.enable = true;
  programs.btop.settings = {
    vim_keys = true;
    show_battery = false;
  };

  home.packages =
    with pkgs;
    [
      ################################## 
      # Common
      ##################################
      lsd
      htop
      tldr
      jq
      fd
      wget
      curl
      eza
      fastfetch
      git

      ################################## 
      # Development
      ##################################
      pkg-config
      sops
      kubectl
      (google-cloud-sdk.withExtraComponents [google-cloud-sdk.components.gke-gcloud-auth-plugin])
      docker
      claude-code
      mkcert
      vscode

      ##################################
      # Productivity
      ##################################
      starship # theme for shell (bash,fish,zsh)
      tmux
      gnupg
      openssl
      ffmpeg
      android-tools

      ##################################
      # Useful Nix related tools
      ##################################
      cachix
      comma # run without install
    ]
    ++ lib.optionals stdenv.isDarwin [
      mas
      m-cli # useful macOS CLI commands
      pinentry-curses
      
      ##################################
      # Entertainment
      ##################################
      iina

      ##################################
      # Productivity
      ##################################
      rectangle
      ice-bar
      shottr
      pinentry_mac
      raycast
      obs-studio
      iterm2
      ntfs-3g
      appcleaner
      stats
      brave-browser
      mongodb-compass

      ##################################
      # Developer Tools
      ##################################
      xcode-install
      dbeaver-community
      cloudflared
      orbstack

      ##################################
      # Study / Research
      ##################################
      mendeley-reference-manager

      ##################################
      # Communication
      ##################################
      zoom-us
      # telegram
    ];
}
