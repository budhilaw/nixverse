{ lib, stdenv, fetchurl, undmg }:

let
  pname = "dbeaver-community";
  version = "25.0.5";
  
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://dbeaver.io/files/${version}/dbeaver-ce-${version}-macos-aarch64.dmg";
      sha256 = "sha256-L6bOyvhlsT4sXL1QDhlJtb8DFfDVw21ixyRenOVdCxU=";
    };
    x86_64-darwin = fetchurl {
      url = "https://dbeaver.io/files/${version}/dbeaver-ce-${version}-macos-x86_64.dmg";
      sha256 = "6eeebb4f3f1ac0043af629d8dacdf7d20daa3da9f6b512d6226798c7d1c1ded5";
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