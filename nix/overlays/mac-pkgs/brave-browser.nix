{
  lib,
  stdenv,
  fetchurl,
  undmg,
}:

let
  inherit (stdenv.hostPlatform) system;
  throwSystem = throw "Unsupported system: ${system}";

  pname = "brave-browser";

  version =
    rec {
      aarch64-darwin = "1.77.101.0";
      x86_64-darwin = aarch64-darwin;
    }
    .${system} or throwSystem;

  sha256 =
    rec {
      aarch64-darwin = "sha256-buZi35oTORCmjHHDa1bsTJMldSADGMYV98PeHVYfhwM="; # 002d4a409827df50674c205fcf2415e855580e385eb422dc44d6a9e61f34f83a
      x86_64-darwin = "sha256-5sMJMN6rYLN1TFaaSbq3mCzr8C4/LrOWz6HMpTRlMSA="; # e6c0c931ac83ba96c00e356ef73365c63609e9a3cf9a9fc4d3a113a0b5266230
    }
    .${system} or throwSystem;

  srcs =
    let
      versionFormatted = with builtins; 
        let 
          parts = lib.strings.splitString "." version;
          major = elemAt parts 0;
          minor = elemAt parts 1;
          patch = elemAt parts 2;
        in
          "${major}${minor}.${patch}";
      
      folder = if system == "aarch64-darwin" then "stable-arm64" else "stable";
      arch = if system == "aarch64-darwin" then "arm64" else "x64";
      base = "https://updates-cdn.bravesoftware.com/sparkle/Brave-Browser";
    in
    rec {
      aarch64-darwin = {
        url = "${base}/stable-arm64/${versionFormatted}/Brave-Browser-arm64.dmg";
        sha256 = sha256;
      };
      x86_64-darwin = {
        url = "${base}/stable/${versionFormatted}/Brave-Browser-x64.dmg";
        sha256 = sha256;
      };
    };

  src = fetchurl (srcs.${system} or throwSystem);

  meta = with lib; {
    description = "Web browser focusing on privacy";
    homepage = "https://brave.com/";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.mpl20;
    platforms = [
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "brave";
  };

  darwin = stdenv.mkDerivation {
    inherit
      pname
      version
      src
      meta
      ;

    nativeBuildInputs = [ undmg ];

    sourceRoot = "Brave Browser.app";

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/Applications/Brave Browser.app"
      cp -R . "$out/Applications/Brave Browser.app"
      runHook postInstall
    '';
  };
in
darwin 