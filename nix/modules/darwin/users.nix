{ lib, pkgs, ... }:

{
  system.primaryUser = "budhilaw";

  # Listing the user in knownUsers lets nix-darwin manage the login shell
  # through dscl, replacing the old chsh activation hack.
  users.knownUsers = [ "budhilaw" ];
  users.users.budhilaw = {
    # Must match the account's real uid, or nix-darwin skips the user (and
    # stops managing its shell). Hosts where budhilaw isn't 501 override it.
    uid = lib.mkDefault 501;
    gid = 20;
    home = "/Users/budhilaw";
    shell = pkgs.fish;
  };
}
