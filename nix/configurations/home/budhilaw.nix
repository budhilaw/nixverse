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
    username = "budhilaw";
    stateVersion = "25.11";
    homeDirectory = osConfig.users.users.${username}.home;
  };

  within = {
    gpg.enable = true;
    ssh.enable = true;
  };

  # ---------------------------------------------------------------------------
  # SSH keys — personal Mac
  #
  # Private keys are decrypted from secrets/budhilaw-ssh.yaml via SOPS.
  # Uncomment sopsFile after completing the one-time secrets setup:
  #
  #   1. Generate age key:
  #      nix run nixpkgs#age -- keygen -o ~/.config/sops/age/keys.txt
  #      (copy the "public key: age1..." line into .sops.yaml)
  #
  #   2. Create encrypted secrets:
  #      nix run nixpkgs#sops -- secrets/budhilaw-ssh.yaml
  #      (see secrets/budhilaw-ssh.yaml.example for the expected YAML format)
  #
  #   3. Save age private key to 1Password:
  #      cat ~/.config/sops/age/keys.txt
  #
  #   4. darwin-rebuild switch
  # ---------------------------------------------------------------------------
  within.ssh = {
    # sopsFile = ../../../secrets/budhilaw-ssh.yaml;  # uncomment after setup
    privateKeys = [
      "id_ed25519_personal"
      "id_ed25519_hosthatch"
      "id_ed25519_hosthatch_deploy"
      "id_ed25519_hosthatch_deploy_agent"
      "id_ed25519_STB_One"
      "id_ed25519_STB_Two"
    ];
    # Populate after setup: cat ~/.ssh/<name>.pub
    publicKeys = {
      # "id_ed25519_personal" = "ssh-ed25519 AAAA...";
      # "id_ed25519_hosthatch" = "ssh-ed25519 AAAA...";
      # "id_ed25519_hosthatch_deploy" = "ssh-ed25519 AAAA...";
      # "id_ed25519_hosthatch_deploy_agent" = "ssh-ed25519 AAAA...";
      # "id_ed25519_STB_One" = "ssh-ed25519 AAAA...";
      # "id_ed25519_STB_Two" = "ssh-ed25519 AAAA...";
    };
  };

  programs.ssh.matchBlocks = {
    "github.com" = {
      hostname = "github.com";
      user = "git";
      identityFile = "~/.ssh/id_ed25519_personal";
      identitiesOnly = true;
    };
    "github.com-paper" = {
      hostname = "github.com";
      user = "git";
      identityFile = "~/.ssh/id_ed25519_paper";
      identitiesOnly = true;
    };
  };

  imports = lib.attrValues ezModules ++ [
    # --- secrets (SOPS with age key — key stored in 1Password)
    inputs.sops-nix.homeManagerModules.sops
    {
      # Age key location — place this file from 1Password on new machine
      sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

      # Optional: import GPG private key from encrypted secrets
      # Uncomment sopsFile after running: sops secrets/budhilaw-gpg.yaml
      # sops.secrets."gpg_private_key" = {
      #   sopsFile = ../../../secrets/budhilaw-gpg.yaml;
      #   path = "${config.home.homeDirectory}/.local/share/sops-gpg-key.asc";
      #   mode = "0600";
      # };

      programs.git.settings.diff.sopsdiffer.textconv = "sops -d --config /dev/null";
      home.packages = [ pkgs.sops pkgs.age ];
    }
    # --- secrets
  ];
}
