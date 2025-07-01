{
  lib,
  stdenv,
  fetchurl,
  undmg,
}:

let
  inherit (stdenv.hostPlatform) system;
  throwSystem = throw "Unsupported system: ${system}";

  pname = "mongodb-compass";

  version =
    rec {
      aarch64-darwin = "1.46.4";
      x86_64-darwin = aarch64-darwin;
    }
    .${system} or throwSystem;

  sha256 =
    rec {
      aarch64-darwin = "sha256-gwA7G8WYQV5DXms6HY7ruYXItPy4ckXbBB5pWpIwBqo=";
      x86_64-darwin = "sha256-BdZOZevmWeFodU27bib8dKrWxaJFHhqKbq6WojV9UMe=";
    }
    .${system} or throwSystem;

  srcs =
    let
      arch = if system == "aarch64-darwin" then "arm64" else "x64";
      base = "https://downloads.mongodb.com/compass";
    in
    rec {
      aarch64-darwin = {
        url = "${base}/mongodb-compass-${version}-darwin-${arch}.dmg";
        sha256 = sha256;
      };
      x86_64-darwin = {
        url = "${base}/mongodb-compass-${version}-darwin-${arch}.dmg";
        sha256 = sha256;
      };
    };

  src = fetchurl (srcs.${system} or throwSystem);

  meta = with lib; {
    description = "Interactive tool for analyzing MongoDB data";
    homepage = "https://www.mongodb.com/products/compass";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    platforms = [
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "mongodb-compass";
  };

  darwin = stdenv.mkDerivation {
    inherit
      pname
      version
      src
      meta
      ;

    nativeBuildInputs = [ undmg ];

    sourceRoot = "MongoDB Compass.app";

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/Applications/MongoDB Compass.app"
      cp -R . "$out/Applications/MongoDB Compass.app"
      runHook postInstall
    '';
  };
in
darwin 