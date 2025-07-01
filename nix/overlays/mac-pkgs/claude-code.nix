{ lib, stdenv, fetchurl, curl, writeShellScript, cacert }:

# This package always fetches the latest version of Claude Code CLI
let
  pname = "claude-code";
  version = "latest";
  
  # Create a script to download the latest version
  downloadScript = writeShellScript "download-claude-code" ''
    set -eu
    ARCH="$1"
    OUTPUT="$2"
    
    echo "Downloading latest Claude Code CLI for $ARCH..."
    ${curl}/bin/curl --cacert ${cacert}/etc/ssl/certs/ca-bundle.crt -fsSL "https://claude.ai/api/download/claude-code/darwin/$ARCH" -o "$OUTPUT"
    chmod +x "$OUTPUT"
    echo "Download complete."
  '';
in

stdenv.mkDerivation {
  inherit pname version;
  
  dontUnpack = true;
  dontFetch = true;
  
  buildInputs = [ curl cacert ];
  
  buildPhase = ''
    runHook preBuild
    
    ARCH="${if stdenv.isAarch64 then "arm64" else "x64"}"
    ${ downloadScript } "$ARCH" "./claude-code"
    
    runHook postBuild
  '';
  
  installPhase = ''
    runHook preInstall
    
    # Create bin directory
    mkdir -p $out/bin
    
    # Install the binary
    install -m755 ./claude-code $out/bin/claude-code
    
    # Generate shell completions (for future when supported)
    # mkdir -p $out/share/bash-completion/completions
    # mkdir -p $out/share/zsh/site-functions
    # mkdir -p $out/share/fish/vendor_completions.d
    # $out/bin/claude-code completion bash > $out/share/bash-completion/completions/claude-code
    # $out/bin/claude-code completion zsh > $out/share/zsh/site-functions/_claude-code
    # $out/bin/claude-code completion fish > $out/share/fish/vendor_completions.d/claude-code.fish
    
    runHook postInstall
  '';
  
  meta = with lib; {
    description = "Claude Code CLI - command-line interface for Claude AI code assistant";
    homepage = "https://claude.ai/";
    platforms = [ "aarch64-darwin" "x86_64-darwin" ];
    maintainers = with maintainers; [ ];
    mainProgram = "claude-code";
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
  };
} 