{ inputs, ... }:

{
  imports = [ inputs.mac-app-util.darwinModules.default ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup-before-nix-home-manager";
    # Register apps in ~/Applications/Home Manager Apps with Launch Services
    # so old versions stop lingering in "Open With".
    sharedModules = [ inputs.mac-app-util.homeManagerModules.default ];
  };
}
