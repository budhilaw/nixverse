# I have been start to use fully in nix at 9-Feb-2022
# and found how to create flake, home-manager, and darwin in nix
# Here: https://gist.github.com/jmatsushita/5c50ef14b4b96cb24ae5268dab613050

{
  lib,
  pkgs,
  ...
}:

{
  # Apps
  environment.systemPackages = (with pkgs.branches.master; [
    terminal-notifier
  ]);

  # Fonts
  fonts.packages = with pkgs; [
    sketchybar-app-font

    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack
    nerd-fonts.symbols-only
    geist-font
  ];
}
