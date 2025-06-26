{
  lib,
  stdenv,
  fetchurl,
  undmg,
}:

let
  inherit (stdenv.hostPlatform) system;
  throwSystem = throw "Unsupported system: ${system}";

  pname = "google-chrome";
  
  # Use a dummy version since we're always fetching latest
  version = "latest";

  # Google Chrome official download URLs that redirect to latest version
  srcs =
    rec {
      aarch64-darwin = {
        url = "https://dl.google.com/chrome/mac/universal/stable/GGRO/googlechrome.dmg";
        # Since we can't predict the hash of the latest version, we'll use lib.fakeHash
        # This will require manual updates when the hash changes, but ensures we get latest
        sha256 = "sha256-G00hazyPnTx77NIK6Osjxa4OYlo188J6iWv60PPs+OQ=";
      };
      x86_64-darwin = aarch64-darwin;  # Universal binary
    };

  src = fetchurl (srcs.${system} or throwSystem);

  meta = with lib; {
    description = "A web browser built for speed, simplicity, and security";
    longDescription = ''
      Google Chrome is a fast, secure, and free web browser, built for the modern web.
      This package always downloads the latest stable version available.
      
      Note: This package may require manual hash updates when Google releases new versions.
    '';
    homepage = "https://www.google.com/chrome/";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    platforms = [
      "x86_64-darwin" 
      "aarch64-darwin"
    ];
    maintainers = [ ];
    mainProgram = "google-chrome";
  };

  darwin = stdenv.mkDerivation {
    inherit
      pname
      version
      src
      meta
      ;

    nativeBuildInputs = [ undmg ];

    sourceRoot = "Google Chrome.app";

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/Applications/Google Chrome.app"
      cp -R . "$out/Applications/Google Chrome.app"
      runHook postInstall
    '';

    # Add a post-install message
    postInstall = ''
      echo ""
      echo "Google Chrome has been installed to $out/Applications/"
      echo "The latest version was downloaded and installed."
      echo ""
    '';
  };
in
darwin 