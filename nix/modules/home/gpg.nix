# GPG keyring + agent config. Private keys are decrypted by sops-nix and
# imported on activation. SSH authentication is deliberately NOT routed through gpg-agent:
# on macOS the Apple ssh-agent + Keychain handles that (see ssh.nix).
{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.within.gpg;
  keyDir = "${config.home.homeDirectory}/.local/share/sops-gpg";
in
{
  options.within.gpg = {
    enable = lib.mkEnableOption "GPG configuration";

    privateKeys = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = "Map of GPG key entry name -> SOPS file containing it; each is imported into the keyring.";
    };

    trustKeyIds = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Key IDs (0x...) or fingerprints to set to ultimate trust after import.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.gpg = {
      enable = true;
      settings.trust-model = "tofu+pgp";
    };

    # No launchd job: home-manager's darwin gpg-agent agent cannot receive the
    # launchd socket (`--supervised` wants fd 3) and just crash-loops. gpg
    # starts the agent on demand from this config instead.
    home.file.".gnupg/gpg-agent.conf".text = ''
      default-cache-ttl 34560000
      max-cache-ttl 34560000
      pinentry-program ${
        lib.getExe (if pkgs.stdenv.hostPlatform.isDarwin then pkgs.pinentry_mac else pkgs.pinentry-curses)
      }
      allow-loopback-pinentry
      grab
    '';

    programs.fish.interactiveShellInit = ''
      set -gx GPG_TTY (tty)
      gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
    '';
    home.sessionVariables.GPG_TTY = "$(tty)";

    sops.secrets = lib.mapAttrs' (
      name: sopsFile:
      lib.nameValuePair name {
        inherit sopsFile;
        path = "${keyDir}/${name}.asc";
        mode = "0600";
      }
    ) cfg.privateKeys;

    home.activation.importGpgKeys = lib.mkIf (cfg.privateKeys != { }) (
      lib.hm.dag.entryAfter [ "sops-nix" ] ''
        export GNUPGHOME="${config.home.homeDirectory}/.gnupg"
        ${lib.concatMapStringsSep "\n" (name: ''
          if [ -f "${keyDir}/${name}.asc" ]; then
            ${pkgs.gnupg}/bin/gpg --batch --import "${keyDir}/${name}.asc" 2>/dev/null || true
          fi
        '') (lib.attrNames cfg.privateKeys)}
        # --import-ownertrust needs full fingerprints; resolve key IDs first.
        ${lib.concatMapStringsSep "\n" (keyId: ''
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
