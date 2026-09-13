{ inputs, ... }:

{
  flake.overlays.default = _final: prev: {
    # The current stable release, for tools that need a cached/known-good
    # build (node toolchains, goose, k6). Uses legacyPackages so nixpkgs is
    # not re-imported on every evaluation.
    stable = inputs.nixpkgs-stable.legacyPackages.${prev.stdenv.hostPlatform.system};
  };
}
