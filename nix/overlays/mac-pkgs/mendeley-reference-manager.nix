{
  lib,
  stdenv,
  fetchurl,
  unzip,
}:

let
  inherit (stdenv.hostPlatform) system;
  throwSystem = throw "Unsupported system: ${system}";

  pname = "mendeley-reference-manager";
  version = "2.143.0";

  sha256 = "sha256-EHpXd1ZQ3NKxVxNd0M44WuNOrsE0dysD7L4MPbno9nI=";

  src = fetchurl {
    url = "https://static.mendeley.com/bin/desktop/mendeley-reference-manager-${version}-universal.dmg";
    inherit sha256;
  };

  meta = with lib; {
    description = "Research management tool";
    homepage = "https://www.mendeley.com/download-reference-manager/macOS/";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    platforms = [
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    maintainers = [ ];
  };

  appname = "Mendeley Reference Manager";

  darwin = stdenv.mkDerivation {
    inherit
      pname
      version
      src
      meta
      ;

    buildInputs = [ unzip ];

    unpackCmd = ''
      echo "File to unpack: $curSrc"
      if ! [[ "$curSrc" =~ \.dmg$ ]]; then return 1; fi
      mnt=$(mktemp -d -t ci-XXXXXXXXXX)

      function finish {
        echo "Detaching $mnt"
        /usr/bin/hdiutil detach $mnt -force
        rm -rf $mnt
      }
      trap finish EXIT

      echo "Attaching $mnt"
      /usr/bin/hdiutil attach -nobrowse -readonly $src -mountpoint $mnt

      echo "What's in the mount dir"?
      ls -la $mnt/

      echo "Copying contents"
      shopt -s extglob
      DEST="$PWD"
      (cd "$mnt"; cp -a !(Applications) "$DEST/" 2>/dev/null || cp -a . "$DEST/")
    '';

    phases = [
      "unpackPhase"
      "installPhase"
    ];

    sourceRoot = "${appname}.app";

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/Applications/${appname}.app"
      cp -a ./. "$out/Applications/${appname}.app/"
      runHook postInstall
    '';
  };
in
darwin
