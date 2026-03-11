{
  inputs,
  lib,
  pkgs,
  ezModules,
  osConfig,
  config,
  ...
}:

{
  home = rec {
    username = "ericssonbudhilaw";
    stateVersion = "25.11";
    homeDirectory = osConfig.users.users.${username}.home;
  };

  within = {
    gpg.enable = true;
    ssh.enable = true;
  };

  # ---------------------------------------------------------------------------
  # SSH keys — work laptop (Amartha only)
  #
  # Uncomment sopsFile after completing the one-time secrets setup:
  #
  #   1. Generate age key (on work laptop):
  #      nix run nixpkgs#age -- keygen -o ~/.config/sops/age/keys.txt
  #      (copy the "public key: age1..." line into .sops.yaml)
  #
  #   2. Create encrypted secrets:
  #      nix run nixpkgs#sops -- secrets/ericssonbudhilaw-ssh.yaml
  #      (see secrets/ericssonbudhilaw-ssh.yaml.example for YAML format)
  #
  #   3. Save age private key to 1Password:
  #      cat ~/.config/sops/age/keys.txt
  #
  #   4. darwin-rebuild switch
  # ---------------------------------------------------------------------------
  within.ssh = {
    # sopsFile = ../../../secrets/ericssonbudhilaw-ssh.yaml;  # uncomment after setup
    privateKeys = [
      "id_ed25519_amartha"
    ];
    # Populate after setup: cat ~/.ssh/id_ed25519_amartha.pub
    publicKeys = {
      # "id_ed25519_amartha" = "ssh-ed25519 AAAA...";
    };
  };

  programs.ssh.matchBlocks = {
    "github.com" = {
      hostname = "github.com";
      user = "git";
      identityFile = "~/.ssh/id_ed25519_amartha";
      identitiesOnly = true;
    };
  };

  imports = lib.attrValues ezModules ++ [
    # --- secrets (SOPS with age key — key stored in 1Password)
    inputs.sops-nix.homeManagerModules.sops
    {
      # Age key location — place this file from 1Password on new machine
      sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

      programs.git.settings.diff.sopsdiffer.textconv = "sops -d --config /dev/null";
      home.packages = [ pkgs.sops pkgs.age ];
    }
    # --- secrets
  ];
}
