{
  inputs,
  lib,
  pkgs,
  ezModules,
  osConfig,
  ...
}:

{
  home = rec {
    username = "ericssonbudhilaw";
    stateVersion = "25.11";
    homeDirectory = osConfig.users.users.${username}.home;
  };

  within = {
    gpg.enable = true;
  };

  imports = lib.attrValues ezModules ++ [
    # --- secrets
    inputs.sops-nix.homeManagerModules.sops
    {
      sops.gnupg.home = "~/.gnupg";
      programs.git.settings.diff.sopsdiffer.textconv = "sops -d --config /dev/null";
      home.packages = [ pkgs.sops ];
    }
    # --- secrets
  ];

}
