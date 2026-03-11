{
  lib,
  stdenv,
  fetchurl,
}:

let
  inherit (stdenv.hostPlatform) system;
  throwSystem = throw "Unsupported system: ${system}";

  pname = "claude-code";
  version = "2.1.72";

  base = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";

  srcs = {
    aarch64-darwin = fetchurl {
      url = "${base}/${version}/darwin-arm64/claude";
      sha256 = "sha256-xYT1E2LVYmlbxxdQ0cIZb5oODjb9BD4rxoPM/Jo6s9c=";
    };
    x86_64-darwin = fetchurl {
      url = "${base}/${version}/darwin-x64/claude";
      sha256 = "sha256-JLn6GD5CJmQPCiFY53cCsN2GDZIFsb7H5pVgmjCciYY=";
    };
  };

  src = srcs.${system} or throwSystem;
in

stdenv.mkDerivation {
  inherit pname version src;

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp $src $out/bin/claude
    chmod +x $out/bin/claude
    runHook postInstall
  '';

  meta = {
    description = "An agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster";
    homepage = "https://www.anthropic.com/claude-code";
    license = lib.licenses.unfree;
    platforms = [ "aarch64-darwin" "x86_64-darwin" ];
    mainProgram = "claude";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
