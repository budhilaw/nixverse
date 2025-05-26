{ self, ... }:
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
        "mendeley-reference-manager"
        "notion"
      ];
    in

    attrsets.genAttrs packages (name: callPackage ./${name}.nix { })
    // {
      sbar_menus = prev.callPackage "${self}/nix/packages/sketchybar/helpers/menus" { };
      sbar_events = prev.callPackage "${self}/nix/packages/sketchybar/helpers/event_providers" { };
      sbarLua = prev.callPackage "${self}/nix/packages/sketchybar/helpers/sbar.nix" { };
      sketchybarConfigLua = prev.callPackage "${self}/nix/packages/sketchybar" { };
      sf-symbols-font = final.sf-symbols.overrideAttrs (old: {
        pname = "sf-symbols-font";
        installPhase = ''
          runHook preInstall 

          mkdir -p $out/share/fonts
          cp -a Library/Fonts/* $out/share/fonts/

          runHook postInstall
        '';

        meta = old.meta // {
          description = "sf-symbols-font";
        };
      });
    };
}
