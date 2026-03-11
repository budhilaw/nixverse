{
  lib,
  stdenv,
  fetchurl,
  undmg,
}:

let
  inherit (stdenv.hostPlatform) system;
  throwSystem = throw "Unsupported system: ${system}";

  pname = "shottr";

  version =
    rec {
      aarch64-darwin = "1.9.1";
      x86_64-darwin = aarch64-darwin;
    }
    .${system} or throwSystem;

  sha256 =
    rec {
      aarch64-darwin = "sha256-C/15fbz+xSpeEitQBirWuVSEf+O1PWdsBaxDYfUM5bM=";
      x86_64-darwin = aarch64-darwin;
    }
    .${system} or throwSystem;

  srcs =
    let
      base = "https://shottr.cc/dl";
    in
    rec {
      aarch64-darwin = {
        url = "${base}/Shottr-${version}.dmg";
        sha256 = sha256;
      };
      x86_64-darwin = aarch64-darwin;
    };

  src = fetchurl (srcs.${system} or throwSystem);

  meta = with lib; {
    description = "Shottr";
    homepage = "https://shottr.cc/";
    platforms = [
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };

  darwin = stdenv.mkDerivation {
    inherit
      pname
      version
      src
      meta
      ;

    nativeBuildInputs = [ undmg ];

    sourceRoot = "Shottr.app";

    installPhase = ''
      runHook preInstall
      mkdir -p $out/Applications/Shottr.app
      cp -R . $out/Applications/Shottr.app
      runHook postInstall
    '';
  };
in
darwin