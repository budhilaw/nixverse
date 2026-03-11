{
  lib,
  stdenv,
  fetchurl,
  undmg,
}:

let
  inherit (stdenv.hostPlatform) system;
  throwSystem = throw "Unsupported system: ${system}";

  pname = "slack";

  version =
    rec {
      aarch64-darwin = "4.48.100";
      x86_64-darwin = aarch64-darwin;
    }
    .${system} or throwSystem;

  sha256 =
    rec {
      aarch64-darwin = "sha256-vzgxVBRncNQ4mchSgbe9vm3kEiPXHeMlhm3Xq4COi7A=";
      x86_64-darwin = "sha256-5IEIgDxdE2Pnpy3gkJT3Cwzo3hRoTPziFAj30SnapVQ=";
    }
    .${system} or throwSystem;

  srcs =
    let
      arch = if system == "aarch64-darwin" then "arm64" else "x64";
      base = "https://downloads.slack-edge.com/desktop-releases/mac";
    in
    rec {
      aarch64-darwin = {
        url = "${base}/arm64/${version}/Slack-${version}-macOS.dmg";
        sha256 = sha256;
      };
      x86_64-darwin = {
        url = "${base}/x64/${version}/Slack-${version}-macOS.dmg";
        sha256 = sha256;
      };
    };

  src = fetchurl (srcs.${system} or throwSystem);

  meta = with lib; {
    description = "Team communication and collaboration software";
    homepage = "https://slack.com/";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    platforms = [
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "slack";
  };

  darwin = stdenv.mkDerivation {
    inherit
      pname
      version
      src
      meta
      ;

    nativeBuildInputs = [ undmg ];

    sourceRoot = "Slack.app";

    installPhase = ''
      runHook preInstall
      mkdir -p $out/Applications/Slack.app
      cp -R . $out/Applications/Slack.app
      runHook postInstall
    '';
  };
in
darwin 