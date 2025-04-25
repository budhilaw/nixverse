{ inputs, ... }:

{
  imports = [
    ./nodePackages
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

    sketchybar-app-font = prev.stdenv.mkDerivation {
      name = "sketchybar-app-font";
      src = inputs.sketchybar-app-font;
      buildInputs = [
        final.nodejs
        final.nodePackages.svgtofont
      ];
      buildPhase = ''
        ln -s ${final.nodePackages.svgtofont}/lib/node_modules ./node_modules
        node ./build.js
      '';
      installPhase = ''
        mkdir -p $out/share/fonts
        cp -r dist/*.ttf $out/share/fonts
      '';
    };

    fishPlugins = prev.fishPlugins // {
      nix-env = {
        name = "nix-env";
        src = inputs.nix-env;
      };
    };
  };
}