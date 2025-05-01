{
  lib,
  stdenv,
  fetchurl,
  undmg,
}:

let
  inherit (stdenv.hostPlatform) system;
  throwSystem = throw "Unsupported system: ${system}";

  pname = "mendeley-reference-manager";
  version = "2.132.2";
  
  sha256 = "sha256-/rR9AJcw5wAX8UuNyX700TUOTZ87jCe7MVWmf4y00x0="; # 683dc8a17a83fb0e1dc51783ef6c7651604ea35714e6a361ed12793e6547048d

  src = fetchurl {
    url = "https://static.mendeley.com/bin/desktop/mendeley-reference-manager-${version}-universal.dmg";
    inherit sha256;
  };

  meta = with lib; {
    description = "Research management tool";
    homepage = "https://www.mendeley.com/download-reference-manager/macOS/";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    platforms = [ "x86_64-darwin" "aarch64-darwin" ];
    maintainers = [ ];
  };

  darwin = stdenv.mkDerivation {
    inherit
      pname
      version
      src
      meta
      ;

    nativeBuildInputs = [ undmg ];

    sourceRoot = "Mendeley Reference Manager.app";

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/Applications/Mendeley Reference Manager.app"
      cp -R . "$out/Applications/Mendeley Reference Manager.app"
      runHook postInstall
    '';
  };
in
darwin 