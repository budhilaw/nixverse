{ lib, stdenv, curl, makeWrapper, writeShellScript }:

let
  pname = "claude-code";
  version = "latest";

  # Create a wrapper script that downloads the binary if it doesn't exist
  wrapper = writeShellScript "claude-code-wrapper" ''
    set -e
    
    CACHE_DIR="$HOME/.cache/claude-code"
    BIN_DIR="$CACHE_DIR/bin"
    ARCH="$(uname -m | sed 's/x86_64/x64/;s/arm64/arm64/')"
    BINARY="$BIN_DIR/claude-code"
    
    mkdir -p "$BIN_DIR"
    
    # Check if binary exists and is executable
    if [ ! -x "$BINARY" ]; then
      echo "Downloading Claude Code CLI for $ARCH..."
      curl -fsSL "https://claude.ai/api/download/claude-code/darwin/$ARCH" -o "$BINARY"
      chmod +x "$BINARY"
      echo "Download complete."
    fi
    
    exec "$BINARY" "$@"
  '';
in

stdenv.mkDerivation {
  inherit pname version;
  
  dontUnpack = true;
  
  nativeBuildInputs = [ makeWrapper ];
  
  installPhase = ''
    runHook preInstall
    
    # Create bin directory
    mkdir -p $out/bin
    
    # Install the wrapper script
    makeWrapper ${wrapper} $out/bin/claude-code
    
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