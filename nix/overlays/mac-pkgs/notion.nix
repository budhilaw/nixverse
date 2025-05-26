{
  lib,
  stdenv,
  fetchurl,
  undmg,
}:

let
  inherit (stdenv.hostPlatform) system;
  throwSystem = throw "Unsupported system: ${system}";

  pname = "notion";

  version =
    rec {
      aarch64-darwin = "4.11.1";
      x86_64-darwin = aarch64-darwin;
    }
    .${system} or throwSystem;

  sha256 =
    rec {
      aarch64-darwin = "sha256-HVuj4jjwyOunEPEmsvAMpQx1I3iRvbj8+DbZdTcMh1w="; # 1d5ba3e238f0c8eba710f126b2f00ca50c75237891bdb8fcf836d975370c875c
      x86_64-darwin = "sha256-g3vLxuFYSdeiOGRp6cDfKU/XlyAKAxdRMWIJEyzeeIU="; # 837bcbc6e15849d7a2836469e9c0fdf294fd79720a03b175316209132cde8785
    }
    .${system} or throwSystem;

  srcs =
    let
      arch = if system == "aarch64-darwin" then "-arm64" else "";
      base = "https://desktop-release.notion-static.com";
    in
    rec {
      aarch64-darwin = {
        url = "${base}/Notion-${version}${arch}.dmg";
        sha256 = sha256;
      };
      x86_64-darwin = {
        url = "${base}/Notion-${version}${arch}.dmg";
        sha256 = sha256;
      };
    };

  src = fetchurl (srcs.${system} or throwSystem);

  meta = with lib; {
    description = "App to write, plan, collaborate, and get organised";
    homepage = "https://www.notion.com/";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    platforms = [
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "notion";
  };

  darwin = stdenv.mkDerivation {
    inherit
      pname
      version
      src
      meta
      ;

    nativeBuildInputs = [ undmg ];

    sourceRoot = "Notion.app";

    installPhase = ''
      runHook preInstall
      mkdir -p $out/Applications/Notion.app
      cp -R . $out/Applications/Notion.app
      runHook postInstall
    '';
  };
in
darwin 