{ lib, stdenv, fetchurl, undmg }:

let
  pname = "jetbrains-toolbox";
  version = "3.3.1";
  build = "3.3.1.75249";

  sources = {
    aarch64-darwin = fetchurl {
      url = "https://download.jetbrains.com/toolbox/jetbrains-toolbox-${build}-arm64.dmg";
      sha256 = "sha256-B6Kv5rAJqlQfSn83KUUi933kiN8AGRU+mom8e4sRZEM=";
    };
    x86_64-darwin = fetchurl {
      url = "https://download.jetbrains.com/toolbox/jetbrains-toolbox-${build}.dmg";
      sha256 = "sha256-aNTPYaayR3aA/Q44rYRSJyBddYona/oZ8u2YYjf3uxc=";
    };
  };
in

stdenv.mkDerivation {
  inherit pname version;
  
  src = sources.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
  
  nativeBuildInputs = [ undmg ];
  
  sourceRoot = ".";
  
  installPhase = ''
    mkdir -p "$out/Applications"
    cp -r "JetBrains Toolbox.app" "$out/Applications/"
  '';
  
  meta = with lib; {
    description = "JetBrains tools manager";
    homepage = "https://www.jetbrains.com/toolbox-app/";
    platforms = [ "aarch64-darwin" "x86_64-darwin" ];
    maintainers = with maintainers; [ ];
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
  };
} 