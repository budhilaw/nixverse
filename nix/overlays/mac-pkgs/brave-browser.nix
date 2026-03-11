{
  lib,
  stdenv,
  fetchurl,
  undmg,
}:

let
  inherit (stdenv.hostPlatform) system;
  throwSystem = throw "Unsupported system: ${system}";

  pname = "brave-browser";
  version = "1.87.192.0";
  build = "187.192";

  sha256 =
    {
      aarch64-darwin = "sha256-ELSKbJzYdl3eMCMkdbs/UAhNoKKNwESqOTD7PxPwB2A=";
      x86_64-darwin = "sha256-HpMeLs2USb8tWGp2H5eaTxHh+NGQ5NFrXrbG7bcP8PA=";
    }
    .${system} or throwSystem;

  srcs = {
    aarch64-darwin = {
      url = "https://updates-cdn.bravesoftware.com/sparkle/Brave-Browser/stable-arm64/${build}/Brave-Browser-arm64.dmg";
      sha256 = sha256;
    };
    x86_64-darwin = {
      url = "https://updates-cdn.bravesoftware.com/sparkle/Brave-Browser/stable/${build}/Brave-Browser-x64.dmg";
      sha256 = sha256;
    };
  };

  src = fetchurl (srcs.${system} or throwSystem);

  meta = with lib; {
    description = "Web browser focusing on privacy";
    homepage = "https://brave.com/";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.mpl20;
    platforms = [
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "brave";
  };

  darwin = stdenv.mkDerivation {
    inherit
      pname
      version
      src
      meta
      ;

    nativeBuildInputs = [ undmg ];

    sourceRoot = "Brave Browser.app";

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/Applications/Brave Browser.app"
      cp -R . "$out/Applications/Brave Browser.app"
      runHook postInstall
    '';
  };
in
darwin
