/**
  How to use this modules:

  ```nix
  imports = [
    inputs.r17x.nixModules.nix
    {
      nix-settings.use = "minimal";
      nix-settings.inputs-to-registry = true;
    }
  ];
  ```
*/

{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.nix-settings;

  hasFull = cfg.use == "full";
  isFull = lib.optionals hasFull;
in
{
  options.nix-settings = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to enable the nix settings.
      '';
    };

    use = lib.mkOption {
      type = lib.types.enum [
        "minimal"
        "full"
      ];
      default = "minimal";
      description = ''
        The nix settings to use.

        Valid values are: "minimal", "full".
      '';
    };
    inputs-to-registry = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to add inputs to the registry.

        it will turn inputs.<NAME> to the nix.registry.<NAME>.flake
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    nix =
      rec {
        nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

        registry =
          {
            nixpkgs.flake = inputs.nixpkgs;
          }
          // lib.optionalAttrs cfg.inputs-to-registry (
            lib.attrsets.concatMapAttrs (name: flake: {
              ${name} = { inherit flake; };
            }) (lib.attrsets.filterAttrs (_: lib.isType "flake") inputs)
          );

        settings =
          {
            nix-path = nixPath;
            experimental-features =
              [
                "flakes"
                "nix-command"
              ]
              ++ isFull [
                "pipe-operators"
                "auto-allocate-uids"
                "ca-derivations"
              ];
          }
          // (
            lib.optionalAttrs hasFull {

              accept-flake-config = true;
              download-attempts = 1;
              fallback = true;
              http-connections = 0;
              max-jobs = "auto";

              trusted-users = [
                "budhilaw"
                "root"
                "nixos"
              ];

              trusted-substituters = [
                "https://nix-community.cachix.org"
                "https://budhilaw.cachix.org/"
                "https://devenv.cachix.org"
              ];

              trusted-public-keys = [
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                "budhilaw.cachix.org-1:Fbyz4CIpkeY0n6XkK3v2lznxqAvA+vGBJGHBahaI53A="
                "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
              ];
            }
            // (lib.optionalAttrs (pkgs.stdenv.isDarwin && pkgs.stdenv.isAarch64) {
              extra-platforms = "x86_64-darwin aarch64-darwin";
            })
          );
      }
      // (lib.optionalAttrs hasFull {
        optimise.automatic = true;

        # enable garbage-collection on weekly and delete-older-than 30 day
        gc = {
          automatic = true;
          options = "--delete-older-than 30d";
        };

        extraOptions = ''
          keep-outputs = true
          keep-derivations = true
          auto-allocate-uids = false
        '';
      });
  };
}
