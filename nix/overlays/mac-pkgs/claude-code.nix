{
  lib,
  stdenv,
  fetchurl,
  nodejs_20,
  makeWrapper,
}:

let
  pname = "claude-code";
  version = "1.0.69";
  
  src = fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-UTYBdTNPWNY5ISjE+OI/S9nSrxIo0FCunwSUZxdmvkE=";
  };
in

stdenv.mkDerivation {
  inherit pname version src;
  
  nativeBuildInputs = [ nodejs_20 makeWrapper ];
  
  buildPhase = ''
    runHook preBuild
    
    export HOME=$TMPDIR
    tar -xf $src
    cd package
    
    # Create the node_modules directory structure
    mkdir -p $out/lib/node_modules/@anthropic-ai/claude-code
    cp -r . $out/lib/node_modules/@anthropic-ai/claude-code/
    
    # Make the CLI script executable
    chmod +x $out/lib/node_modules/@anthropic-ai/claude-code/cli.js
    
    runHook postBuild
  '';
  
  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/bin
    
    # Create a wrapper script for the CLI
    # The package doesn't have a bin/claude binary, but a cli.js file at the root
    # We create a wrapper that runs: node cli.js
    makeWrapper ${nodejs_20}/bin/node $out/bin/claude \
      --add-flags "$out/lib/node_modules/@anthropic-ai/claude-code/cli.js" \
      --set DISABLE_AUTOUPDATER 1 \
      --set NODE_PATH $out/lib/node_modules
    
    runHook postInstall
  '';
  
  meta = {
    description = "An agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster";
    homepage = "https://github.com/anthropics/claude-code";
    downloadPage = "https://www.npmjs.com/package/@anthropic-ai/claude-code";
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "claude";
  };
} 