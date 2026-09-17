# Shared home-manager profile for budhilaw on every host. Host-specific parts
# (private keys, GPG keys, dev-tool toggles) are set from the host config via
# home-manager.users.budhilaw.
{
  lib,
  pkgs,
  ezModules,
  osConfig,
  ...
}:

{
  imports = lib.attrValues ezModules;

  home = rec {
    username = "budhilaw";
    stateVersion = "25.11";
    homeDirectory = osConfig.users.users.${username}.home;
  };

  within.ssh = {
    enable = true;
    publicKeys = {
      id_ed25519_personal = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAVtM3ijBnlhJzKAttdc22AbJzHt0iTqB+A9t5LKrLrv ericsson@budhilaw.com";
      id_ed25519_amartha = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbz/EiDGc02i6MGql1xxUS3GDSH6G+fFRmiVIoO2BMX ericsson.budhilaw@amartha.com";
      # business: Cloudnan servers and the HostHatch VPS
      id_ed25519_business = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIESjcM8xIL8wJ99n+FvGqpgXK+HoZE0BKOUt1Ktr3dDD ericsson@cloudnan.com business";
    };
  };

  programs.ssh.settings = {
    # Homelab over the tailnet — no browser OTP, works from anywhere enrolled.
    homelab = {
      HostName = "100.64.0.1";
      User = "budhilaw";
      IdentityFile = "~/.ssh/id_ed25519_personal";
      IdentitiesOnly = true;
    };
    # Homelab through Cloudflare Access (email OTP) — fallback when not on the tailnet.
    homelab-cf = {
      HostName = "ssh.budhilaw.com";
      User = "budhilaw";
      ProxyCommand = "${pkgs.cloudflared}/bin/cloudflared access ssh --hostname %h";
    };
    "github.com" = {
      User = "git";
      IdentityFile = "~/.ssh/id_ed25519_personal";
      IdentitiesOnly = true;
    };
    "bitbucket.org" = {
      User = "git";
      IdentityFile = "~/.ssh/id_ed25519_amartha";
      IdentitiesOnly = true;
    };
    hosthatch = {
      HostName = "31.57.224.49";
      User = "kai";
      Port = 14048;
      IdentityFile = "~/.ssh/id_ed25519_business";
      IdentitiesOnly = true;
    };
    onidel = {
      HostName = "104.250.122.107";
      User = "root";
      IdentityFile = "~/.ssh/id_ed25519_personal";
      IdentitiesOnly = true;
    };
    cloudnan-db = {
      HostName = "165.245.184.200";
      User = "root";
      IdentityFile = "~/.ssh/id_ed25519_business";
      IdentitiesOnly = true;
    };
    cloudnan-grpc = {
      HostName = "152.42.208.47";
      User = "root";
      IdentityFile = "~/.ssh/id_ed25519_business";
      IdentitiesOnly = true;
    };
    cloudnan-core = {
      HostName = "168.144.36.205";
      User = "root";
      IdentityFile = "~/.ssh/id_ed25519_business";
      IdentitiesOnly = true;
    };
    cloudnan-runner = {
      HostName = "206.189.88.184";
      User = "root";
      IdentityFile = "~/.ssh/id_ed25519_business";
      IdentitiesOnly = true;
    };
  };
}
