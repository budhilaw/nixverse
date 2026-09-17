{
  description = "nixverse — one flake for all of my machines";

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      imports = [ ./nix ];
    };

  inputs = {
    ## nixpkgs — unstable is the default, stable is exposed as `pkgs.stable`
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/release-25.11";

    ## flake plumbing
    flake-parts.url = "github:hercules-ci/flake-parts";
    # Pinned to ehllie/ez-configs#27 (stdenv.isDarwin -> hostPlatform fix).
    # Switch back to "github:ehllie/ez-configs" once that PR is merged.
    ez-configs.url = "github:magistau/ez-configs/dc144599881813cdfacef08da8ef33c0ab47f798";
    ez-configs.inputs.nixpkgs.follows = "nixpkgs";
    ez-configs.inputs.flake-parts.follows = "flake-parts";
    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";

    ## macOS
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    # Determinate Nix owns the daemon on macOS; this module writes our custom
    # settings to /etc/nix/nix.custom.conf and keeps determinate-nixd current.
    determinate.url = "github:DeterminateSystems/determinate";
    # Keeps Launch Services / Spotlight / Dock in sync with Nix-installed apps.
    mac-app-util.url = "github:hraban/mac-app-util";
    mac-app-util.inputs.nixpkgs.follows = "nixpkgs";

    ## Linux
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    ## home
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
  };
}
