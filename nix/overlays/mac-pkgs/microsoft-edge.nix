{
  lib,
  stdenv,
  fetchurl,
  undmg,
}:

let
  inherit (stdenv.hostPlatform) system;
  throwSystem = throw "Unsupported system: ${system}";

  pname = "microsoft-edge";

  version =
    rec {
      aarch64-darwin = "135.0.3179.54";
      x86_64-darwin = aarch64-darwin;
    }
    .${system} or throwSystem;

  # UUID required for the download URL
  uuid =
    rec {
      aarch64-darwin = "07494f63-fb3c-45d8-9302-bedbe6515189";
      x86_64-darwin = aarch64-darwin;
    }
    .${system} or throwSystem;

  sha256 =
    rec {
      aarch64-darwin = "sha256-CGBQVbl99e0U3iVJTpnEIj6361fR2+WNSROKoSMK23k="; # 08605055b97df5ed14de25494e99c4223eb7eb57d1dbe58d49138aa1230adb79
      x86_64-darwin = aarch64-darwin;
    }
    .${system} or throwSystem;

  srcs =
    let
      base = "https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files";
    in
    rec {
      aarch64-darwin = {
        url = "${base}/${uuid}/MicrosoftEdge-${version}.dmg";
        sha256 = sha256;
      };
      x86_64-darwin = aarch64-darwin;
    };

  src = fetchurl (srcs.${system} or throwSystem);

  meta = with lib; {
    description = "Multi-platform web browser";
    homepage = "https://www.microsoft.com/en-us/edge";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    platforms = [
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "edge";
  };

  darwin = stdenv.mkDerivation {
    inherit
      pname
      version
      src
      meta
      ;

    nativeBuildInputs = [ undmg ];

    sourceRoot = "Microsoft Edge.app";

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/Applications/Microsoft Edge.app"
      cp -R . "$out/Applications/Microsoft Edge.app"
      runHook postInstall
    '';
  };
in
darwin 