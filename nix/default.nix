{
  lib,
  inputs,
  ...
}:

{

  imports = [
    inputs.process-compose-flake.flakeModule
    inputs.ez-configs.flakeModule

    ./devShells.nix
    ./overlays

    ./modules/flake/module-config.nix
    {
      modulesGen.flakeModules.dir = ./modules/flake;
      modulesGen.crossModules.dir = ./modules/cross;
    }

    ./modules/flake/rebuild-script.nix
    {
      rebuild-scripts.enable = true;
    }
  ];

  flake = {
    users.budhilaw = rec {
      username = "budhilaw";
      gh.url = "https://github.com/budhilaw";
      keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDlZ2nm/I+pgwdJGpFzlN4HcQ19VCidrHx5QypgZVehe ericsson@budhilaw.com"
      ];
    };

    # --- shareable nixpkgs configurations
    nixpkgs = {
      config = {
        allowBroken = true;
        allowUnfree = true;
        tarball-ttl = 0;
        contentAddressedByDefault = false;
      };

      overlays = lib.attrValues inputs.self.overlays;
    };
  };

  ezConfigs = {
    root = ./.;
    globalArgs = {
      inherit (inputs) self;
      inherit inputs;
      inherit (inputs.self)
        crossModules
        ;
    };

    home.modulesDirectory = ./modules/home;
    home.configurationsDirectory = ./configurations/home;

    darwin.modulesDirectory = ./modules/darwin;
    darwin.configurationsDirectory = ./configurations/darwin;
    darwin.hosts = {
      budhilaw.userHomeModules = [ "budhilaw" ];
    };
    
    # Add NixOS configuration
    nixos.modulesDirectory = ./modules/nixos;
    nixos.configurationsDirectory = ./configurations/nixos;
    nixos.hosts = {
      budhilaw.userHomeModules = [ "budhilaw" ];
    };
  };

  perSystem =
    {
      pkgs,
      system,
      inputs',
      ...
    }:
    {
      formatter = inputs'.nixpkgs.legacyPackages.nixfmt-rfc-style;

      # process-compose."ai" = {
      #   imports = [
      #     inputs.services-flake.processComposeModules.default
      #   ];
      #   services.ollama.ollamaX.enable = true;
      #   services.ollama.ollamaX.dataDir = "$HOME/.process-compose/ai/data/ollamaX";
      #   services.ollama.ollamaX.models = [
      #     "qwen2.5-coder"
      #     # "deepseek-r1:1.5b"
      #   ];
      # };

      # just for demo - https://x.com/dhh/status/1897982683772317776
      process-compose."mysql" = {
        imports = [
          inputs.services-flake.processComposeModules.default
        ];
        services.mysql."m1" = {
          enable = true;
          package = pkgs.mariadb_114;
          settings.mysqld.port = 3307;
        };
      };

      _module.args = {
        inherit (inputs.self);
        # extraModuleArgs = {
        #   inherit (inputs.self);
        # };
        pkgs = import inputs.nixpkgs {
          inherit system;
          inherit (inputs.self.nixpkgs) config overlays;
        };
      };
    };
}
