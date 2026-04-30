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

    # direnv 2.37.1 fish test is killed in the macOS Nix sandbox; skip checks.
    direnv = prev.direnv.overrideAttrs (_: { doCheck = false; });

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

fishPlugins = prev.fishPlugins // {
      nix-env = {
        name = "nix-env";
        src = inputs.nix-env;
      };
    };
  };
}