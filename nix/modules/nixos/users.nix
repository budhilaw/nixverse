{ pkgs, ... }:

{
  users.users.budhilaw = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAVtM3ijBnlhJzKAttdc22AbJzHt0iTqB+A9t5LKrLrv ericsson@budhilaw.com"
    ];
  };
}
