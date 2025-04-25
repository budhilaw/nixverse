{ ... }:
{
  flake.overlays.macos =
    final: prev:
    let
      inherit (prev.lib) attrsets;
      callPackage = prev.newScope { };
      packages = [
        "brave-browser"
        "microsoft-edge"
        "obs-studio"
        "orbstack"
        "telegram"
        "shottr"
        "dbeaver-community"
        "cursor"
        "jetbrains-toolbox"
        "slack"
        "iterm2"
      ];
    in

    attrsets.genAttrs packages (name: callPackage ./${name}.nix { });
}
