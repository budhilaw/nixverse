#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nodePackages.node2nix coreutils gnused jq curl

set -euo pipefail

cd "$(dirname "$0")"

latest=$(curl -s https://registry.npmjs.org/@anthropic-ai/claude-code/latest | jq -r '.version')
current=$(grep 'version =' claude-code.nix | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')

if [ "$latest" = "$current" ]; then
  echo "Already up to date: $current"
  exit 0
fi

echo "Updating from $current to $latest"

# Update version in the nix file
sed -i.bak -E "s/version = \"[0-9]+\.[0-9]+\.[0-9]+\"/version = \"$latest\"/" claude-code.nix

# Create a temporary package.json
cat > package.json <<EOF
{
  "name": "@anthropic-ai/claude-code",
  "version": "$latest",
  "dependencies": {}
}
EOF

# Generate lock file
npm install --package-lock-only
cp package-lock.json .

# Get new hash for tgz file
url="https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-$latest.tgz"
hash=$(nix-prefetch-url --unpack "$url")

# Update src hash
sed -i.bak -E "s|hash = \"sha256-[^\"]+\"|hash = \"sha256-$hash\"|" claude-code.nix

# Generate npm deps hash
npm_deps_hash=$(nix-prefetch -f '<nixpkgs>' --expr "
  (import <nixpkgs> {}).buildNpmPackage {
    name = \"claude-code\";
    version = \"$latest\";
    src = builtins.fetchTarball \"$url\";
    npmDepsHash = \"\";
    dontNpmBuild = true;
  }
" 2>&1 | grep 'npmDepsHash' | cut -d'"' -f2)

# Update npmDepsHash
sed -i.bak -E "s|npmDepsHash = \"sha256-[^\"]+\"|npmDepsHash = \"sha256-$npm_deps_hash\"|" claude-code.nix

# Clean up
rm -f package.json claude-code.nix.bak *.tgz

echo "Update complete!" 