{
  lib,
  stdenv,
  fetchurl,
  undmg,
}:

let
  inherit (stdenv.hostPlatform) system;
  throwSystem = throw "Unsupported system: ${system}";

  pname = "brave-browser";

  version =
    rec {
      aarch64-darwin = "1.81.131";
      x86_64-darwin = aarch64-darwin;
    }
    .${system} or throwSystem;

  sha256 =
    rec {
      aarch64-darwin = "sha256-NQzUf4RhWoQMxuDoEmwI4nPkCZkE5UIopSoQdcH1Kj8=";
      x86_64-darwin = "sha256-0yBPBSf7V/c56AmTYdZuyj/D+N67WeHpD5UjuCEfHjs=";
    }
    .${system} or throwSystem;

  srcs =
    let
      # Remove the trailing .0 from version for GitHub releases
      versionTag = "v${version}";
      arch = if system == "aarch64-darwin" then "arm64" else "x64";
      base = "https://github.com/brave/brave-browser/releases/download";
    in
    rec {
      aarch64-darwin = {
        url = "${base}/${versionTag}/Brave-Browser-arm64.dmg";
        sha256 = sha256;
      };
      x86_64-darwin = {
        url = "${base}/${versionTag}/Brave-Browser-x64.dmg";
        sha256 = sha256;
      };
    };

  src = fetchurl (srcs.${system} or throwSystem);

  meta = with lib; {
    description = "Web browser focusing on privacy";
    homepage = "https://brave.com/";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.mpl20;
    platforms = [
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "brave";
  };

  darwin = stdenv.mkDerivation {
    inherit
      pname
      version
      src
      meta
      ;

    nativeBuildInputs = [ undmg ];

    sourceRoot = "Brave Browser.app";

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/Applications/Brave Browser.app"
      cp -R . "$out/Applications/Brave Browser.app"
      runHook postInstall
    '';
  };
in
darwin 