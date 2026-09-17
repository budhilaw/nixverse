# MacBook Pro M2 — the office machine. Same profile as the Air; carries the
# work (Amartha) keys plus the personal SSH key for GitHub and the homelab.
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
      privateKeys = [
        "id_ed25519_personal"
        "id_ed25519_amartha"
      ];
    };
  };
}
