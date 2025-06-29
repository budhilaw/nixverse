{
  lib,
  stdenv,
  fetchurl,
  cpio,
  gzip,
  xar,
}:

let
  inherit (stdenv.hostPlatform) system;
  throwSystem = throw "Unsupported system: ${system}";

  pname = "zoom-us";

  version =
    rec {
      aarch64-darwin = "6.5.1";
      x86_64-darwin = aarch64-darwin;
    }
    .${system} or throwSystem;

  sha256 =
    rec {
      aarch64-darwin = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # TODO: Update with actual hash
      x86_64-darwin = aarch64-darwin;
    }
    .${system} or throwSystem;

  srcs =
    let
      base = "https://zoom.us/client/latest";
    in
    rec {
      aarch64-darwin = {
        url = "${base}/ZoomInstaller.pkg";
        sha256 = sha256;
      };
      x86_64-darwin = aarch64-darwin;
    };

  src = fetchurl (srcs.${system} or throwSystem);

  meta = with lib; {
    description = "Video conferencing and web conferencing service";
    homepage = "https://zoom.us/";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    platforms = [
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "zoom.us";
  };

  darwin = stdenv.mkDerivation {
    inherit
      pname
      version
      src
      meta
      ;

    nativeBuildInputs = [ 
      cpio
      gzip
      xar
    ];

    unpackPhase = ''
      runHook preUnpack
      
      # Extract the .pkg installer
      xar -xf $src
      
      # Extract the payload
      cd zoomus.pkg
      gunzip -c Payload | cpio -i
      
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/Applications
      cp -R Applications/zoom.us.app $out/Applications/
      runHook postInstall
    '';
  };
in
darwin 