{
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  nixpkgs.hostPlatform = "x86_64-linux";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault true;
  hardware.enableRedistributableFirmware = true;

  # Intel Quick Sync for Jellyfin (the container gets /dev/dri).
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      libvdpau-va-gl
    ];
  };

  swapDevices = [
    {
      device = "/swap.img";
      size = 4 * 1024;
    }
  ];

  # Seagate Backup Plus (USB, 1 TB): media, downloads, photos, Seafile data.
  fileSystems."/mnt/hdd-ext" = {
    device = "/dev/disk/by-uuid/d767a15c-bd70-49a1-9f07-993a521d1abc";
    fsType = "ext4";
    options = [
      "nofail"
      "x-systemd.device-timeout=10s"
    ];
  };
}
