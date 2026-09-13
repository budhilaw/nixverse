{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.terminal-notifier ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack
    nerd-fonts.symbols-only
    geist-font
  ];
}
