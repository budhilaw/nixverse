##################################################################
#                       Development shells
##################################################################
{ inputs, self, ... }:

{
  imports = [
    inputs.pre-commit-hooks.flakeModule
  ];

  perSystem =
    {
      pkgs,
      system,
      config,
      ...
    }:
    {
      pre-commit.check.enable = true;
      pre-commit.devShell = self.devShells.default;
      pre-commit.settings.hooks = {
        actionlint.enable = true;
        shellcheck.enable = true;
        stylua.enable = true;
        luacheck.enable = false;
        deadnix.enable = true;
        deadnix.excludes = [ "nix/overlays/nodePackages/node2nix" ];
        nixfmt-rfc-style.enable = true;
        dune-fmt.enable = true;
        dune-fmt.settings.extraRuntimeInputs = [ pkgs.ocamlPackages.ocamlformat ];
        dune-fmt.files = "apps/rin.rocks";
        dune-fmt.entry = "dune build @fmt --root=apps/rin.rocks --auto-promote";
      };

      devShells =
        let
          inherit (pkgs) lib;
          mutFirstChar =
            f: s:
            let
              firstChar = f (lib.substring 0 1 s);
              rest = lib.substring 1 (-1) s;

            in
            # matched = builtins.match "(.)(.*)" s;
            # firstChar = f (lib.elemAt matched 0);
            # rest = lib.elemAt matched 1;
            firstChar + rest;

          toCamelCase_ =
            sep: s:
            mutFirstChar lib.toLower (lib.concatMapStrings (mutFirstChar lib.toUpper) (lib.splitString sep s));

          toCamelCase =
            s:
            builtins.foldl' (s: sep: toCamelCase_ sep s) s [
              "-"
              "_"
              "."
            ];

          mkNodeShell =
            name:
            let
              node = pkgs.${name};
              corepackShim = pkgs.nodeCorepackShims.overrideAttrs (_: {
                buildInputs = [ node ];
              });
            in
            pkgs.mkShell {
              description = "${name} Development Environment";
              buildInputs = [
                node
                corepackShim
              ];
            };

          mkGoShell =
            name:
            let
              go = pkgs.${name};
            in
            pkgs.mkShell {
              description = "${name} Development Environment";
              buildInputs = with pkgs; [
                go
              ];
              shellHook = ''
                export GOPATH="$(${go}/bin/go env GOPATH)"
                export PATH="$PATH:$GOPATH/bin"
              '';
            };

          mkShell =
            pkgName: name:
            if lib.strings.hasPrefix "nodejs_" pkgName then
              mkNodeShell name
            else if lib.strings.hasPrefix "go_" pkgName then
              mkGoShell name
            else
              builtins.throw "Unknown package ${pkgName} for making shell environment";

          mkShells =
            pkgName:
            let
              mkShell_ = mkShell pkgName;
            in
            builtins.foldl' (acc: name: acc // { "${toCamelCase name}" = mkShell_ name; }) { } (
              builtins.filter (lib.strings.hasPrefix pkgName) (builtins.attrNames pkgs)
            );

        in
        ####################################################################################################
        #    see nodejs_* definitions in {https://search.nixos.org/packages?query=nodejs_}
        #
        #    versions: 14, 18, 20, 22, Latest
        #
        #    $ nix develop github:budhilaw/nixverse#<nodejsVERSION>
        #
        #
        mkShells "nodejs_"
        // mkShells "go_"
        // rec {
          default = pkgs.mkShell {
            shellHook = ''
              ${config.pre-commit.installationScript}
            '';
            packages = [ inputs.clan-core.packages.${system}.clan-cli ];
          };

          #
          #
          #    $ nix develop github:budhilaw/nixverse#go
          #
          #
          go = pkgs.mkShell {
            description = "Go Development Environment";
            nativeBuildInputs = with pkgs; [
              go
              gopls
              go-outline
              gocode-gomod
              golangci-lint
              godef
              golint
              delve
              go-tools
              go-migrate
              go-mockery
              protoc-gen-go
            ];
            shellHook = ''
              export GOPATH="$(${pkgs.go}/bin/go env GOPATH)"
              export PATH="$PATH:$GOPATH/bin"
            '';
          };

          #
          #
          #    $ nix develop github:budhilaw/nixverse#rust
          #
          #
          rust= pkgs.mkShell {
            description = "Rust  Development Environment";
            # declared ENV variables when starting shell
            RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

            nativeBuildInputs = with pkgs; [
              rustup
              rustc
              cargo
              gcc
              rustfmt
              clippy
              pkg-config
            ];
          };

          #
          #
          #    $ nix develop github:budhilaw/nixverse#nodejs
          #
          #
          nodejs = pkgs.mkShell {
            description = "Node.js LTS Development Environment";
            nativeBuildInputs = with pkgs; [
              nodejs_22  # Current LTS version
              nodePackages.npm
              nodePackages.yarn
              nodePackages.pnpm
            ];
            shellHook = ''
              echo "Node.js LTS Development Environment"
              echo "Node.js version: $(node --version)"
              echo "npm version: $(npm --version)"
              echo "yarn version: $(yarn --version)"
              echo "pnpm version: $(pnpm --version)"
            '';
          };

          #
          #
          #    $ nix develop github:budhilaw/nixverse#python
          #
          #
          python = pkgs.mkShell {
            description = "Python Development Environment";
            nativeBuildInputs = with pkgs; [
              python3
              python3Packages.pip
              python3Packages.virtualenv
              python3Packages.setuptools
              python3Packages.wheel
              python3Packages.black
              python3Packages.flake8
              python3Packages.mypy
              python3Packages.pytest
              python3Packages.ipython
            ];
            shellHook = ''
              echo "Python Development Environment"
              echo "Python version: $(python --version)"
              echo "Available tools: pip, virtualenv, black, flake8, mypy, pytest, ipython"
              
              # Create and activate virtual environment if it doesn't exist
              if [ ! -d ".venv" ]; then
                echo "Creating virtual environment..."
                python -m venv .venv
              fi
              
              echo "To activate virtual environment: source .venv/bin/activate"
            '';
          };
        };

    };
}
