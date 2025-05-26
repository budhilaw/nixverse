{
  lib,
  pkgs,
  ezModules,
  crossModules,
  config,
  inputs,
  ...
}:

{
  imports = lib.attrValues (ezModules // crossModules) ++ [
    inputs.nixos-wsl.nixosModules.wsl
    inputs.home-manager.nixosModules.home-manager
    inputs.vscode-server.nixosModules.default
  ];

  # Set the system state version
  system.stateVersion = "25.05";
  
  # Set the platform to x86_64-linux
  nixpkgs.hostPlatform = "x86_64-linux";

  # Enable nix settings module
  nix-settings = {
    enable = true;
    use = "full";
    inputs-to-registry = true;
  };

  # WSL-specific settings
  wsl = {
    enable = true;
    defaultUser = "budhilaw";
    startMenuLaunchers = true;
    # Enable integration with Docker Desktop (needs to be installed)
    docker-desktop.enable = true;
  };

  # Root filesystem configuration for WSL
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=4G" "mode=755" ];
  };

  # Home Manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    sharedModules = [
      {
        home.stateVersion = config.system.stateVersion;
      }
    ];
  };

  # User configuration
  users.users.budhilaw = {
    isNormalUser = true;
    home = "/home/budhilaw";
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    shell = pkgs.fish;
  };

  # Enable basic services
  services = {
    xserver.enable = true;
    xserver.displayManager.gdm.enable = true;
    xserver.desktopManager.gnome.enable = true;
  };

  # Enable networking
  networking = {
    hostName = lib.mkDefault "budhilaw";
    networkmanager.enable = true;
  };

  # System packages
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    vscode
  ];

  # Enable nix-ld for running unpatched dynamic binaries
  programs.nix-ld.enable = true;

  # Enable command-not-found functionality
  programs.command-not-found.enable = true;

  # Enable VS Code Server for WSL
  services.vscode-server.enable = true;
} 
