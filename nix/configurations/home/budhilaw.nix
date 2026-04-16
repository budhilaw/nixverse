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
      privateKeys = {
        gpg_personal_key = "${inputs.self}/secrets/budhilaw-gpg.yaml";
        gpg_amartha_key  = "${inputs.self}/secrets/amartha-gpg.yaml";
      };
      trustKeyIds = [
        "0xBD838B746BAA8C5F"
        "0x32B604FD91055131"
      ];
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
      "id_ed25519_amartha"
    ];
    publicKeys = {
      id_ed25519_personal = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAVtM3ijBnlhJzKAttdc22AbJzHt0iTqB+A9t5LKrLrv ericsson@budhilaw.com";
      id_ed25519_amartha = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbz/EiDGc02i6MGql1xxUS3GDSH6G+fFRmiVIoO2BMX ericsson.budhilaw@amartha.com";
      id_ed25519_hosthatch = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINL8bYvG9NzButmdWR/hnhv0Uxm+JNbEvMf+kxPIbRSg ericsson.budhilaw@gmail.com";
      id_ed25519_hosthatch_deploy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOdx1ld3dde+kYD+8WvU8z2qipJO6LkQhEc6S+3/mKpK github-actions-deploy";
      id_ed25519_hosthatch_deploy_agent = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAU/BJNdUSN4kszY2hFKNAkkDUly1wfLUdijZ5BQWCsJ github-actions-deploy-agent";
    };
  };

  programs.ssh.matchBlocks = {
    "github.com" = {
      hostname = "github.com";
      user = "git";
      identityFile = "~/.ssh/id_ed25519_personal";
      identitiesOnly = true;
    };
    "bitbucket.org" = {
      hostname = "bitbucket.org";
      user = "git";
      identityFile = "~/.ssh/id_ed25519_amartha";
      identitiesOnly = true;
    };
    "hosthatch" = {
      hostname = "31.57.224.49";
      user = "kai";
      port = 14048;
      identityFile = "~/.ssh/id_ed25519_hosthatch";
      identitiesOnly = true;
    };
    "onidel" = {
      hostname = "104.250.122.107";
      user = "root";
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
