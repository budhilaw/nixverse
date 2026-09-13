# SSH client config + key material. Public keys are plain files; private keys
# come from a sops file and are only present on hosts that set `sopsFile`.
{
  lib,
  config,
  ...
}:

let
  cfg = config.within.ssh;
in
{
  options.within.ssh = {
    enable = lib.mkEnableOption "SSH key management";

    privateKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Names of private keys in sopsFile to place in ~/.ssh/.";
    };

    sopsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "SOPS file holding the private keys. Leave null on hosts that must not carry them.";
    };

    publicKeys = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Map of key name -> public key content, written as ~/.ssh/<name>.pub.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."*" = {
        AddKeysToAgent = "yes";
        ServerAliveInterval = 60;
        ServerAliveCountMax = 3;
        # macOS: keys are added to the Apple ssh-agent + Keychain on first use.
        UseKeychain = "yes";
      };
    };

    home.file = lib.mapAttrs' (
      name: content: lib.nameValuePair ".ssh/${name}.pub" { text = content; }
    ) cfg.publicKeys;

    sops.secrets = lib.mkIf (cfg.sopsFile != null) (
      lib.listToAttrs (
        map (
          name:
          lib.nameValuePair "ssh_${name}" {
            key = name;
            path = "${config.home.homeDirectory}/.ssh/${name}";
            mode = "0600";
            sopsFile = cfg.sopsFile;
          }
        ) cfg.privateKeys
      )
    );
  };
}
