{ inputs, ... }:

{
  imports = [
    ./mac-pkgs
  ];

  flake.overlays.default = final: prev: {
    inherit (inputs.nixpkgs-stable.legacyPackages.${prev.stdenv.hostPlatform.system})
      nixd
      nixf
      nixt
      ;

    branches =
      let
        pkgsFrom =
          branch: system:
          import branch {
            inherit system;
            inherit (inputs.self.nixpkgs) config;
          };
      in
      {
        master = pkgsFrom inputs.nixpkgs-master prev.stdenv.system;
        stable = pkgsFrom inputs.nixpkgs-stable prev.stdenv.system;
        unstable = pkgsFrom inputs.nixpkgs-unstable prev.stdenv.system;
      };

    nixfmt = prev.nixfmt-rfc-style;

    # atuin 18.4.0 has a broken test (atuin_server crate resolution)
    # in nixpkgs-unstable — skip tests until upstream fixes it
    atuin = prev.atuin.overrideAttrs (_: {
      doCheck = false;
    });

    fishPlugins = prev.fishPlugins // {
      nix-env = {
        name = "nix-env";
        src = inputs.nix-env;
      };
    };
  };
}