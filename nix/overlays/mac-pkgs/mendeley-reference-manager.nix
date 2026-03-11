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
  version = "2.143.0";
  
  sha256 = "sha256-EHpXd1ZQ3NKxVxNd0M44WuNOrsE0dysD7L4MPbno9nI=";

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