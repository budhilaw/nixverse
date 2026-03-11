{
  lib,
  stdenv,
  fetchurl,
  unzip,
}:

let
  inherit (stdenv.hostPlatform) system;
  throwSystem = throw "Unsupported system: ${system}";

  pname = "telegram";

  # see version history https://desktop.telegram.org/changelog
  version = "12.5";
  build = "278815";

  sha256 =
    rec {
      aarch64-darwin = "sha256-79OzpA5rm+xSHb/aerHLPn0FV8lvdrM3dhJL4Iephs0=";
      x86_64-darwin = aarch64-darwin;
    }
    .${system} or throwSystem;

  srcs =
    rec {
      aarch64-darwin = {
        url = "https://osx.telegram.org/updates/Telegram-${version}.${build}.app.zip";
        sha256 = sha256;
      };
      x86_64-darwin = aarch64-darwin;
    };

  src = fetchurl (srcs.${system} or throwSystem);

  meta = with lib; {
    description = "Telegram Desktop";
    homepage = "https://tdesktop.com/";
    license = licenses.gpl3Only;
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

    nativeBuildInputs = [ unzip ];

    sourceRoot = "Telegram.app";

    installPhase = ''
      runHook preInstall
      mkdir -p $out/Applications/Telegram.app
      cp -R . $out/Applications/Telegram.app
      runHook postInstall
    '';
  };
in
darwin
