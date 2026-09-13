# Age key lives in 1Password; restore it to ~/.config/sops/age/keys.txt on a
# new machine before the first rebuild.
{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  home.packages = [
    pkgs.sops
    pkgs.age
  ];

  programs.git.settings.diff.sopsdiffer.textconv = "sops -d --config /dev/null";
}
