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
      aarch64-darwin = "4.43.51";
      x86_64-darwin = aarch64-darwin;
    }
    .${system} or throwSystem;

  sha256 =
    rec {
      aarch64-darwin = "sha256-+9yPOtj2tCl29Te7FxJkI1hzJv4KRyvhVUzH5q5j0N0="; # fbdc8f3ad8f6b42976f537bb17126423587326fe0a472be1554cc7e6ae63d0dd
      x86_64-darwin = "sha256-DsYW1LbCnR2s1zXG+2rLUdlMWwW1lxyLh+FtlbMbH7w="; # 0ec14540b667430ebe97b18d861bf8763fba4c5cad94a2cbb5e1d3bb46f6b1bc
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