# NixOS-WSL distro on the Windows gaming PC. Windows itself stays imperative;
# this is the Linux userland (shell, git, dev shells) managed from nixverse.
{
  inputs,
  lib,
  pkgs,
  ezModules,
  ...
}:

{
  imports = lib.attrValues ezModules ++ [ inputs.nixos-wsl.nixosModules.default ];

  networking.hostName = "gaming-wsl";
  system.stateVersion = "25.11";
  nixpkgs.hostPlatform = "x86_64-linux";

  wsl = {
    enable = true;
    defaultUser = "budhilaw";
    startMenuLaunchers = true;
    # Docker Desktop for Windows provides the docker socket + CLI.
    docker-desktop.enable = true;
  };

  # Lets VS Code / Cursor remote servers and other prebuilt binaries run.
  programs.nix-ld.enable = true;

  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
  ];
}
