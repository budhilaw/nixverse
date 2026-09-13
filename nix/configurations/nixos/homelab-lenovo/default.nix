# Lenovo M920Q in Malang — media, photos, files, password vault, DNS.
# Install: see README "Homelab: first install". Deploy afterwards with
#   nixos-rebuild switch --flake ~/.config/nixverse#homelab-lenovo \
#     --target-host homelab --build-host homelab --ask-sudo-password
{
  inputs,
  lib,
  pkgs,
  ezModules,
  ...
}:

{
  imports = lib.attrValues ezModules ++ [
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
    ./hardware.nix
    ./disko.nix
    ./services.nix
    ./containers.nix
  ];

  networking.hostName = "homelab-lenovo";
  system.stateVersion = "25.11";

  # eno1 gets 192.168.18.75 from the router (reserve it there).
  networking.useDHCP = lib.mkDefault true;
  networking.nameservers = [
    "1.1.1.1"
    "8.8.8.8"
  ];

  # Docker publishes container ports through its own iptables chain, which
  # bypasses this firewall — the LAN reaches 53/80/443/8096/... exactly as it
  # did on Ubuntu. This list is only for services running on the host itself.
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    trustedInterfaces = [ "tailscale0" ];
    # containers on the shared bridge reach the host-side SOCKS proxy
    interfaces."br-homelab".allowedTCPPorts = [ 1080 ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  users.users.budhilaw.extraGroups = [ "docker" ];

  # Disk health + hardware error reporting, as on the Ubuntu install.
  services.smartd.enable = true;
  hardware.rasdaemon.enable = true;

  # Prebuilt vendor binaries (cloudnan-agent) need a conventional loader.
  programs.nix-ld.enable = true;

  environment.systemPackages = with pkgs; [
    git
    vim
    htop
    smartmontools
    pciutils
    usbutils
  ];

  # No workstation toolchain on the server.
  home-manager.users.budhilaw.within.dev.enable = false;
}
