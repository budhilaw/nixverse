{ inputs, lib, ... }:

{
  imports = [
    inputs.ez-configs.flakeModule
    inputs.git-hooks.flakeModule
    ./dev-shells.nix
    ./overlays.nix
  ];

  # flake-parts types nixosModules as deferred modules; do the same for the
  # other two so ez-configs' exported paths pass `nix flake check`.
  options.flake = lib.genAttrs [ "darwinModules" "homeModules" ] (
    _:
    lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      default = { };
    }
  );

  config = {
    # nixpkgs settings shared by every host and by the per-system `pkgs`.
    flake.lib.nixpkgs = {
      config.allowUnfree = true;
      overlays = [ inputs.self.overlays.default ];
    };

    # ez-configs maps directories to outputs:
    #   configurations/darwin/<host>.nix -> darwinConfigurations.<host>
    #   configurations/nixos/<host>/     -> nixosConfigurations.<host>
    #   configurations/home/<user>.nix   -> home-manager user module
    #   modules/{darwin,nixos,home}/*    -> ezModules, imported by each host
    ezConfigs = {
      root = ./.;
      globalArgs = {
        inherit inputs;
        inherit (inputs) self;
      };

      home.modulesDirectory = ./modules/home;
      home.configurationsDirectory = ./configurations/home;

      darwin.modulesDirectory = ./modules/darwin;
      darwin.configurationsDirectory = ./configurations/darwin;
      darwin.hosts.macbook-air.userHomeModules = [ "budhilaw" ];

      nixos.modulesDirectory = ./modules/nixos;
      nixos.configurationsDirectory = ./configurations/nixos;
      nixos.hosts = {
        homelab-lenovo.userHomeModules = [ "budhilaw" ];
        gaming-wsl.userHomeModules = [ "budhilaw" ];
      };
    };

    perSystem =
      { system, inputs', ... }:
      {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          inherit (inputs.self.lib.nixpkgs) config overlays;
        };

        formatter = inputs'.nixpkgs.legacyPackages.nixfmt;
      };
  };
}
