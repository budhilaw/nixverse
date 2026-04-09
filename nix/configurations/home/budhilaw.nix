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
    gpg = {
      enable = true;
      sopsFile = "${inputs.self}/secrets/budhilaw-gpg.yaml";
      privateKeys = [ "gpg_private_key" ];
      trustKeyIds = [ "0xBD838B746BAA8C5F" ];
    };
    ssh.enable = true;
  };

  within.ssh = {
    sopsFile = "${inputs.self}/secrets/budhilaw-ssh.yaml";
    privateKeys = [
      "id_ed25519_personal"
      "id_ed25519_hosthatch"
      "id_ed25519_hosthatch_deploy"
      "id_ed25519_hosthatch_deploy_agent"
      "id_ed25519_STB_One"
      "id_ed25519_STB_Two"
    ];
  };

  programs.ssh.matchBlocks = {
    "github.com" = {
      hostname = "github.com";
      user = "git";
      identityFile = "~/.ssh/id_ed25519_personal";
      identitiesOnly = true;
    };
};

  imports = lib.attrValues ezModules ++ [
    # --- nix-index pre-built database
    inputs.nix-index-database.homeModules.nix-index

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
