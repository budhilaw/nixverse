{
  lib,
  stdenv,
  fetchurl,
  undmg,
  unzip,
}:

let
  inherit (stdenv.hostPlatform) system;
  throwSystem = throw "Unsupported system: ${system}";

  pname = "iterm2";

  version =
    rec {
      aarch64-darwin = "3.5.14";
      x86_64-darwin = aarch64-darwin;
    }
    .${system} or throwSystem;

  # SHA hash for iTerm2 v3.5.13
  sha256 =
    rec {
      aarch64-darwin = "sha256-WFvRGeTPOl5r+m87av7PQW8C4o+NgaOh6UmFXaBYy90=";
      x86_64-darwin = aarch64-darwin;
    }
    .${system} or throwSystem;

  srcs =
    let
      # Convert version format from "3.5.14" to "3_5_14" for URL
      versionFormatted = builtins.replaceStrings ["."] ["_"] version;
    in
    rec {
      aarch64-darwin = {
        url = "https://iterm2.com/downloads/stable/iTerm2-${versionFormatted}.zip";
        inherit sha256;
      };
      x86_64-darwin = aarch64-darwin;
    };

  src = fetchurl (srcs.${system} or throwSystem);

  meta = with lib; {
    description = "Replacement for Terminal and the successor to iTerm";
    homepage = "https://iterm2.com/";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.gpl2Plus;
    platforms = platforms.darwin;
    maintainers = with maintainers; [ tricktron lnl7 ];
  };

  darwin = stdenv.mkDerivation {
    inherit
      pname
      version
      src
      meta
      ;

    nativeBuildInputs = [ unzip ];
    
    sourceRoot = "iTerm.app";

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/Applications/iTerm.app"
      cp -R . "$out/Applications/iTerm.app"
      runHook postInstall
    '';
  };
in
darwin 