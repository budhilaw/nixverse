{ inputs, ... }:

{
  imports = [ inputs.nix-index-database.homeModules.nix-index ];

  programs.nix-index = {
    enable = true;
    enableFishIntegration = false;
    enableBashIntegration = false;
  };
  # `, <cmd>` runs a program without installing it.
  programs.nix-index-database.comma.enable = true;
}
