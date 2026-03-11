{ lib, stdenv, unzip, fetchurl }:

let
  pname = "cursor";
  version = "2.6.18";
  sha = "68fbec5aed9da587d1c6a64172792f505bafa252";

  sources = {
    aarch64-darwin = fetchurl {
      url = "https://downloads.cursor.com/production/${sha}/darwin/arm64/Cursor-darwin-arm64.zip";
      sha256 = "sha256-7alxe3q6vl73FMZ1UT5kuGhrfH2+Hksx0EzWVRBPtVI=";
    };
    x86_64-darwin = fetchurl {
      url = "https://downloads.cursor.com/production/${sha}/darwin/x64/Cursor-darwin-x64.zip";
      sha256 = "sha256-Jo5I3JoQR6r/+U3LH4lmKx0J87PmL5wAeGcxnKc35ec=";
    };
  };
in

stdenv.mkDerivation {
  inherit pname version;
  
  src = sources.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
  
  nativeBuildInputs = [ unzip ];
  
  sourceRoot = ".";
  
  installPhase = ''
    mkdir -p "$out/Applications"
    cp -r "Cursor.app" "$out/Applications/"
    
    # Create bin directory and symlink the binary
    mkdir -p "$out/bin"
    ln -s "$out/Applications/Cursor.app/Contents/Resources/app/bin/code" "$out/bin/cursor"
  '';
  
  meta = with lib; {
    description = "Write, edit, and chat about your code with AI";
    homepage = "https://www.cursor.com/";
    platforms = [ "aarch64-darwin" "x86_64-darwin" ];
    maintainers = with maintainers; [ ];
    mainProgram = "cursor";
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
  };
} 