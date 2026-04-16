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

    privateKeys = mkOption {
      type = types.attrsOf types.path;
      default = {};
      example = literalExpression ''
        {
          gpg_personal_key = ''${inputs.self}/secrets/budhilaw-gpg.yaml;
          gpg_amartha_key  = ''${inputs.self}/secrets/amartha-gpg.yaml;
        }
      '';
      description = ''
        Map of GPG key entry name → SOPS-encrypted YAML file containing it.
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

    # Decrypt GPG private keys via sops-nix (each key may live in its own file)
    sops.secrets = mapAttrs' (name: sopsFile: nameValuePair name {
      inherit sopsFile;
      path = "${config.home.homeDirectory}/.local/share/sops-gpg/${name}.asc";
      mode = "0600";
    }) cfg.privateKeys;

    # Auto-import GPG keys and set trust after sops-nix decrypts them
    home.activation.importGpgKeys = mkIf (cfg.privateKeys != {}) (
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
        ) (attrNames cfg.privateKeys)}

        # Set ultimate trust. --import-ownertrust needs full fingerprints,
        # so resolve short key IDs (0x...) to fingerprints via --with-colons.
        ${concatMapStringsSep "\n" (keyId: ''
          fpr=$(${pkgs.gnupg}/bin/gpg --with-colons --fingerprint "${keyId}" 2>/dev/null \
                  | ${pkgs.gawk}/bin/awk -F: '/^fpr:/ { print $10; exit }')
          if [ -n "$fpr" ]; then
            echo "$fpr:6:" | ${pkgs.gnupg}/bin/gpg --import-ownertrust 2>/dev/null || true
          fi
        '') cfg.trustKeyIds}
      ''
    );
  };
}

