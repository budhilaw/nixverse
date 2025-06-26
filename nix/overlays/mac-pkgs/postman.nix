{
  lib,
  stdenv,
  fetchurl,
  unzip,
}:

let
  inherit (stdenv.hostPlatform) system;
  throwSystem = throw "Unsupported system: ${system}";

  pname = "postman";
  
  # Use a dummy version since we're always fetching latest
  version = "latest";

  # Postman official download URLs
  srcs =
    rec {
      aarch64-darwin = {
        url = "https://dl.pstmn.io/download/latest/osx_arm64";
        sha256 = "sha256-KOvYt3VL1hZAyf6T+3whMTyhHgndnlZO0e3L1KtDxqE=";
      };
      x86_64-darwin = {
        url = "https://dl.pstmn.io/download/latest/osx_64";
        sha256 = "sha256-0000000000000000000000000000000000000000000="; # Will be updated when building on x86_64
      };
    };

  src = fetchurl (srcs.${system} or throwSystem);

  meta = with lib; {
    description = "API platform for building and using APIs";
    longDescription = ''
      Postman is a collaboration platform for API development. Postman's 
      features simplify each step of building an API and streamline collaboration 
      so you can create better APIs—faster.
      
      This package always downloads the latest version available.
    '';
    homepage = "https://www.postman.com/";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    platforms = [
      "x86_64-darwin" 
      "aarch64-darwin"
    ];
    maintainers = [ ];
    mainProgram = "postman";
  };

  darwin = stdenv.mkDerivation {
    inherit
      pname
      version
      src
      meta
      ;

    nativeBuildInputs = [ unzip ];

    unpackPhase = ''
      unzip "$src" -d .
    '';

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/Applications"
      cp -R Postman.app "$out/Applications/"
      runHook postInstall
    '';

    # Add a post-install message
    postInstall = ''
      echo ""
      echo "Postman has been installed to $out/Applications/"
      echo "The latest version was downloaded and installed."
      echo ""
    '';
  };
in
darwin 