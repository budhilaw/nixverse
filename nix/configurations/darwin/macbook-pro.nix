# MacBook Pro M2 — the office machine. Same profile as the Air, but carries
# only the work (Amartha) keys and only the base Homebrew set.
{
  inputs,
  lib,
  ezModules,
  ...
}:

{
  imports = lib.attrValues ezModules;

  networking.hostName = "macbook-pro";
  networking.computerName = "macbook-pro";

  # uid 501 on this Mac is IT's `admin` account and 502 was the old
  # ericssonbudhilaw account, so budhilaw was created third. If `id -u` says
  # otherwise, activation warns "unexpected uid" and skips the user: fix it here.
  users.users.budhilaw.uid = 503;

  system.stateVersion = 4;
  nixpkgs.hostPlatform = "aarch64-darwin";

  documentation.enable = false;
  system.tools.darwin-uninstaller.enable = false;

  environment.variables = {
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
  };

  home-manager.users.budhilaw = {
    within.gpg = {
      enable = true;
      privateKeys.gpg_amartha_key = "${inputs.self}/secrets/amartha-gpg.yaml";
      trustKeyIds = [ "0x32B604FD91055131" ];
    };
    within.ssh = {
      sopsFile = "${inputs.self}/secrets/budhilaw-ssh.yaml";
      privateKeys = [ "id_ed25519_amartha" ];
    };
  };
}
