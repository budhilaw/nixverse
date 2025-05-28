{
  lib,
  stdenv,
  fetchurl,
  _7zz,
}:

let
  inherit (stdenv.hostPlatform) system;
  throwSystem = throw "Unsupported system: ${system}";

  pname = "siyuan";

  version =
    rec {
      aarch64-darwin = "3.1.30";
      x86_64-darwin = aarch64-darwin;
    }
    .${system} or throwSystem;

  sha256 =
    rec {
      aarch64-darwin = "sha256-Doxq3xzkXOWK1pW+b4Bk1c61pS/LYPQhf7r9czhLUvw="; # 0e8c6adf1ce45ce58ad695be6f8064d5ceb5a52fcb60f4217fbafd73384b52fc
      x86_64-darwin = "sha256-xCVm178E6janlPsBCTMLos2f65gkgsKEgRHARP8cFFQ="; # c42566d7bf44ea36a7a8f4b09330e2a0bed9fe9b8242a284811e044f6c9c1544
    }
    .${system} or throwSystem;

  srcs =
    let
      arch = if system == "aarch64-darwin" then "-arm64" else "";
      base = "https://github.com/siyuan-note/siyuan/releases/download";
    in
    rec {
      aarch64-darwin = {
        url = "${base}/v${version}/siyuan-${version}-mac${arch}.dmg";
        sha256 = sha256;
      };
      x86_64-darwin = {
        url = "${base}/v${version}/siyuan-${version}-mac${arch}.dmg";
        sha256 = sha256;
      };
    };

  src = fetchurl (srcs.${system} or throwSystem);

  meta = with lib; {
    description = "Local-first personal knowledge management system";
    homepage = "https://github.com/siyuan-note/siyuan";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    platforms = [
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "siyuan";
  };

  darwin = stdenv.mkDerivation {
    inherit
      pname
      version
      src
      meta
      ;

    nativeBuildInputs = [ _7zz ];

    sourceRoot = "SiYuan.app";

    installPhase = ''
      runHook preInstall
      mkdir -p $out/Applications/SiYuan.app
      cp -R . $out/Applications/SiYuan.app
      runHook postInstall
    '';
  };
in
darwin 