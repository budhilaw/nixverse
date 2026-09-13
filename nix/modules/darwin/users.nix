{ pkgs, ... }:

{
  system.primaryUser = "budhilaw";

  # Listing the user in knownUsers lets nix-darwin manage the login shell
  # through dscl, replacing the old chsh activation hack.
  users.knownUsers = [ "budhilaw" ];
  users.users.budhilaw = {
    uid = 501;
    gid = 20;
    home = "/Users/budhilaw";
    shell = pkgs.fish;
  };
}
