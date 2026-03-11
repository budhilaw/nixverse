{ lib, stdenv, fetchurl, undmg }:

let
  pname = "dbeaver-community";
  version = "26.0.0";

  sources = {
    aarch64-darwin = fetchurl {
      url = "https://dbeaver.io/files/${version}/dbeaver-ce-${version}-macos-aarch64.dmg";
      sha256 = "sha256-WzHVhabcIXnodiXB/5fFCu97YcPibB6N21m/7T8/aqo=";
    };
    x86_64-darwin = fetchurl {
      url = "https://dbeaver.io/files/${version}/dbeaver-ce-${version}-macos-x86_64.dmg";
      sha256 = "sha256-G1Xv4nucb0uCjboS1rvtfy6ri0oHPHZmu+jea9PC6Q4=";
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
    cp -r "DBeaver.app" "$out/Applications/"
    
    # Create bin directory and symlink the binary
    mkdir -p "$out/bin"
    ln -s "$out/Applications/DBeaver.app/Contents/MacOS/dbeaver" "$out/bin/dbeaver"
  '';
  
  meta = with lib; {
    description = "Universal database tool and SQL client";
    homepage = "https://dbeaver.io/";
    license = licenses.asl20;
    platforms = [ "aarch64-darwin" "x86_64-darwin" ];
    maintainers = with maintainers; [ ];
  };
} 