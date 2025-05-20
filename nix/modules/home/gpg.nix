{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.within.gpg;
in
{
  options.within.gpg = {
    enable = mkEnableOption "GPG configuration";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.gnupg ];

    programs.gpg = {
      enable = true;
      settings = {
        trust-model = "tofu+pgp";
      };
    };

    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      defaultCacheTtl = 34560000;
      maxCacheTtl = 34560000;
      pinentryPackage = if pkgs.stdenv.isDarwin 
        then pkgs.pinentry_mac
        else pkgs.pinentry-curses;
      extraConfig = ''
        allow-loopback-pinentry
      '';
    };

    programs.fish.interactiveShellInit = mkIf (!pkgs.stdenv.isDarwin) ''
      # Set GPG_TTY for pinentry
      set -gx GPG_TTY (tty)
      # Refresh gpg-agent tty in case user switches into an X session
      gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
    '';

    home.sessionVariables = mkIf (!pkgs.stdenv.isDarwin) {
      GPG_TTY = "$(tty)";
    };
  };
}

