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
      aarch64-darwin = "6.7.7.76486";
      x86_64-darwin = aarch64-darwin;
    }
    .${system} or throwSystem;

  sha256 =
    rec {
      aarch64-darwin = "sha256-Wl8nghOfwGYxwzVjCScMeuiowhKLPYV04cagOpnzGUs=";
      x86_64-darwin = "sha256-DsLM7ILqbjoqvsXtv0NspqP/FvxXK9SEbMrkU75Oqcw=";
    }
    .${system} or throwSystem;

  srcs =
    let
      base = "https://cdn.zoom.us/prod";
      arch = if system == "aarch64-darwin" then "arm64/" else "";
    in
    rec {
      aarch64-darwin = {
        url = "${base}/${version}/${arch}zoomusInstallerFull.pkg";
        sha256 = sha256;
      };
      x86_64-darwin = {
        url = "${base}/${version}/zoomusInstallerFull.pkg";
        sha256 = sha256;
      };
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

    dontUnpack = true;
    dontPatch = true;
    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      
      # Create temporary directory for extraction
      mkdir -p tmp
      cd tmp
      
      # Extract the .pkg installer
      ${xar}/bin/xar -xf $src
      
      # Find the main package and extract it
      for pkg in *.pkg; do
        if [ -f "$pkg/Payload" ]; then
          cd "$pkg"
          ${gzip}/bin/gunzip -c Payload | ${cpio}/bin/cpio -i
          break
        fi
      done
      
      # Install the application
      mkdir -p $out/Applications
      if [ -d "Applications/zoom.us.app" ]; then
        cp -R Applications/zoom.us.app $out/Applications/
      elif [ -d "zoom.us.app" ]; then
        cp -R zoom.us.app $out/Applications/
      else
        echo "Could not find zoom.us.app in extracted package"
        find . -name "*.app" -type d
        exit 1
      fi
      
      runHook postInstall
    '';
  };
in
darwin 