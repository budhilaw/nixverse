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
      "id_ed25519_cloudnan_deploy"
    ];
    publicKeys = {
      id_ed25519_personal = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAVtM3ijBnlhJzKAttdc22AbJzHt0iTqB+A9t5LKrLrv ericsson@budhilaw.com";
      id_ed25519_amartha = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbz/EiDGc02i6MGql1xxUS3GDSH6G+fFRmiVIoO2BMX ericsson.budhilaw@amartha.com";
      id_ed25519_hosthatch = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINL8bYvG9NzButmdWR/hnhv0Uxm+JNbEvMf+kxPIbRSg ericsson.budhilaw@gmail.com";
      id_ed25519_hosthatch_deploy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOdx1ld3dde+kYD+8WvU8z2qipJO6LkQhEc6S+3/mKpK github-actions-deploy";
      id_ed25519_hosthatch_deploy_agent = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAU/BJNdUSN4kszY2hFKNAkkDUly1wfLUdijZ5BQWCsJ github-actions-deploy-agent";
      id_ed25519_cloudnan_deploy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIESjcM8xIL8wJ99n+FvGqpgXK+HoZE0BKOUt1Ktr3dDD ericsson@cloudnan.com cloudnan-deploy";
    };
  };

  programs.ssh.settings = {
    # Homelab (Malang) — reached from anywhere via Cloudflare Tunnel + Access.
    # cloudflared proxies the SSH stream to ssh.budhilaw.com; Access gates it
    # behind an email OTP login. LAN IP 192.168.18.75 is unreachable off-site.
    "homelab" = {
      HostName = "ssh.budhilaw.com";
      User = "budhilaw";
      ProxyCommand = "${pkgs.cloudflared}/bin/cloudflared access ssh --hostname %h";
    };
    "github.com" = {
      HostName = "github.com";
      User = "git";
      IdentityFile = "~/.ssh/id_ed25519_personal";
      IdentitiesOnly = true;
    };
    "bitbucket.org" = {
      HostName = "bitbucket.org";
      User = "git";
      IdentityFile = "~/.ssh/id_ed25519_amartha";
      IdentitiesOnly = true;
    };
    "hosthatch" = {
      HostName = "31.57.224.49";
      User = "kai";
      Port = 14048;
      IdentityFile = "~/.ssh/id_ed25519_hosthatch";
      IdentitiesOnly = true;
    };
    "onidel" = {
      HostName = "104.250.122.107";
      User = "root";
      IdentityFile = "~/.ssh/id_ed25519_personal";
      IdentitiesOnly = true;
    };
    "cloudnan-db" = {
      HostName = "165.245.184.200";
      User = "root";
      IdentityFile = "~/.ssh/id_ed25519_cloudnan_deploy";
      IdentitiesOnly = true;
    };
    "cloudnan-grpc" = {
      HostName = "152.42.208.47";
      User = "root";
      IdentityFile = "~/.ssh/id_ed25519_cloudnan_deploy";
      IdentitiesOnly = true;
    };
    "cloudnan-core" = {
      HostName = "168.144.36.205";
      User = "root";
      IdentityFile = "~/.ssh/id_ed25519_cloudnan_deploy";
      IdentitiesOnly = true;
    };
    "cloudnan-runner" = {
      HostName = "206.189.88.184";
      User = "root";
      IdentityFile = "~/.ssh/id_ed25519_cloudnan_deploy";
      IdentitiesOnly = true;
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
