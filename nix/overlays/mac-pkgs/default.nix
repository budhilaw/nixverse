{ self, ... }:
{
  flake.overlays.macos =
    final: prev:
    let
      inherit (prev.lib) attrsets;
      callPackage = prev.newScope { };
      packages = [
        "brave-browser"
        "obs-studio"
        "orbstack"
        "telegram"
        "shottr"
        "dbeaver-community"
        "cursor"
        "slack"
        "iterm2"
        "mendeley-reference-manager"
        "mongodb-compass"
        "ntfs-3g"
        "postman"
        "zoom-us"
      ];
    in

    attrsets.genAttrs packages (name: callPackage ./${name}.nix { })
    // {
      claude-code = callPackage ./claude-code-alternative.nix { };
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
