{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.within.ssh;
in
{
  options.within.ssh = {
    enable = mkEnableOption "SSH key management";

    privateKeys = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        Names of SSH private keys to decrypt from sopsFile and place in ~/.ssh/.
        Each name corresponds to a key in the SOPS-encrypted YAML file.
      '';
    };

    sopsFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to the SOPS-encrypted YAML file containing private key contents.
        Leave as null until you have set up your age key and created the secrets file.
        See: secrets/README for setup instructions.
      '';
    };

    publicKeys = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = ''
        Map of public key filename (without .pub) to its content.
        These are placed as ~/.ssh/<name>.pub and are safe to store in plaintext.
        Get values via: cat ~/.ssh/<name>.pub
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks."*" = {
        addKeysToAgent = "yes";
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
        extraOptions = {
          UseKeychain = "yes";
        };
      };
    };

    # Place public keys as plain files (not secrets — safe in git)
    home.file = mapAttrs' (
      name: content: nameValuePair ".ssh/${name}.pub" { text = content; }
    ) cfg.publicKeys;

    # Decrypt and place private keys via sops-nix.
    # Only active once sopsFile is set (after age key + secrets are created).
    sops.secrets = mkIf (cfg.sopsFile != null) (
      listToAttrs (
        map (name: nameValuePair "ssh_${name}" {
          key = name;
          path = "${config.home.homeDirectory}/.ssh/${name}";
          mode = "0600";
          sopsFile = cfg.sopsFile;
        }) cfg.privateKeys
      )
    );

    # macOS: add decrypted SSH keys to Apple Keychain after sops-nix places them.
    # This runs on every activation so keys survive reboots via Keychain persistence.
    home.activation.addSshKeysToKeychain = mkIf (cfg.sopsFile != null && pkgs.stdenv.isDarwin) (
      lib.hm.dag.entryAfter [ "sopsNix" ] ''
        for key in ${concatStringsSep " " cfg.privateKeys}; do
          keyPath="${config.home.homeDirectory}/.ssh/$key"
          if [ -f "$keyPath" ]; then
            /usr/bin/ssh-add --apple-use-keychain "$keyPath" 2>/dev/null || true
          fi
        done
      ''
    );
  };
}
