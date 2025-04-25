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
      aarch64-darwin = "3.5.13";
      x86_64-darwin = aarch64-darwin;
    }
    .${system} or throwSystem;

  # SHA hash for iTerm2 v3.5.13
  sha256 =
    rec {
      aarch64-darwin = "sha256-h/j2ykGor1+p6ji96i5RiBMR5/rCQaLHnXYwvFCaN00=";
      x86_64-darwin = aarch64-darwin;
    }
    .${system} or throwSystem;

  srcs =
    rec {
      aarch64-darwin = {
        url = "https://iterm2.com/downloads/stable/iTerm2-3_5_13.zip";
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