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

    sopsFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to the SOPS-encrypted YAML file containing GPG private key(s).
        The file should have keys named like "gpg_private_key" containing
        the ASCII-armored private key export.
      '';
    };

    privateKeys = mkOption {
      type = types.listOf types.str;
      default = [ "gpg_private_key" ];
      description = ''
        Names of GPG private key entries in the sopsFile.
        Each entry will be decrypted and auto-imported into the GPG keyring.
      '';
    };

    trustKeyIds = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        GPG key fingerprints or IDs to set to ultimate trust after import.
        Use the long key ID (e.g., "0xFA185E332882626B") or full fingerprint.
      '';
    };
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
      pinentry.package = if pkgs.stdenv.isDarwin
        then pkgs.pinentry_mac
        else pkgs.pinentry-curses;
      extraConfig = ''
        allow-loopback-pinentry
      '';
    };

    programs.fish.interactiveShellInit = ''
      # Set GPG_TTY for pinentry
      set -gx GPG_TTY (tty)
      # Refresh gpg-agent tty in case user switches into an X session
      gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
    '';

    home.sessionVariables = {
      GPG_TTY = "$(tty)";
    };

    # Decrypt GPG private keys via sops-nix
    sops.secrets = mkIf (cfg.sopsFile != null) (
      listToAttrs (
        map (name: nameValuePair name {
          sopsFile = cfg.sopsFile;
          path = "${config.home.homeDirectory}/.local/share/sops-gpg/${name}.asc";
          mode = "0600";
        }) cfg.privateKeys
      )
    );

    # Auto-import GPG keys and set trust after sops-nix decrypts them
    home.activation.importGpgKeys = mkIf (cfg.sopsFile != null) (
      lib.hm.dag.entryAfter [ "sopsNix" ] ''
        export GNUPGHOME="${config.home.homeDirectory}/.gnupg"

        # Import each decrypted GPG private key
        ${concatMapStringsSep "\n" (name:
          let keyPath = "${config.home.homeDirectory}/.local/share/sops-gpg/${name}.asc";
          in ''
            if [ -f "${keyPath}" ]; then
              ${pkgs.gnupg}/bin/gpg --batch --import "${keyPath}" 2>/dev/null || true
            fi
          ''
        ) cfg.privateKeys}

        # Set ultimate trust for specified key IDs
        ${concatMapStringsSep "\n" (keyId: ''
          echo "${keyId}:6:" | ${pkgs.gnupg}/bin/gpg --import-ownertrust 2>/dev/null || true
        '') cfg.trustKeyIds}
      ''
    );
  };
}

