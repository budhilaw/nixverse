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

          mkPhpShell =
            name:
            let
              php = pkgs.${name};
            in
            pkgs.mkShell {
              description = "${name} Development Environment";
              buildInputs = with pkgs; [
                php
                php.packages.composer
              ];
              shellHook = ''
                export PATH="$PATH:$HOME/.composer/vendor/bin"
              '';
            };

          mkShell =
            pkgName: name:
            if lib.strings.hasPrefix "nodejs_" pkgName then
              mkNodeShell name
            else if lib.strings.hasPrefix "go_" pkgName then
              mkGoShell name
            else if lib.strings.hasPrefix "php" pkgName then
              mkPhpShell name
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
        // mkShells "php"
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
              pkgs.go
              gopls
              go-outline
              gocode-gomod
              godef
              golint
              delve
              go-tools
              go-migrate
              go-mockery
              protoc-gen-go
              # Option 1: Get latest golangci-lint from master branch
              pkgs.branches.master.golangci-lint
              # Option 2: Use custom latest version (uncomment if you prefer this)
              # pkgs.golangci-lint-latest
            ];
            shellHook = ''
              export GOPATH="$(${pkgs.go}/bin/go env GOPATH)"
              export PATH="$PATH:$GOPATH/bin"
              
              echo "Go Development Environment"
              echo "Go version: $(go version)"
              echo "golangci-lint version: $(golangci-lint --version)"
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

            shellHook = ''
              export PATH="$PATH:$HOME/.cargo/bin"
            '';
          };

          #
          #
          #    $ nix develop github:budhilaw/nixverse#nodejs
          #
          #
          nodejs = pkgs.mkShell {
            description = "Node.js LTS Development Environment";
            nativeBuildInputs = with pkgs; [
              nodejs_24
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

          #
          #
          #    $ nix develop github:budhilaw/nixverse#phpdev
          #
          #
          phpdev = pkgs.mkShell {
            description = "PHP Development Environment for Laravel & WordPress";
            nativeBuildInputs = with pkgs; [
              php
              php84Packages.composer
              nodejs_24
              nodePackages.npm
              wp-cli
              curl
              wget
            ];
            shellHook = ''
              echo "PHP Development Environment for Laravel & WordPress"
              echo "PHP version: $(php --version | head -n1)"
              echo "Composer version: $(composer --version)"
              echo "Node.js version: $(node --version)"
              
              # Set up PHP paths
              export PATH="$PATH:$HOME/.composer/vendor/bin"
              
              # Check if we're in fish shell and set up aliases accordingly
              if [ "$SHELL" = "$(which fish)" ] || [ -n "$FISH_VERSION" ]; then
                # Fish shell aliases
                fish -c "alias art='php artisan'"
                fish -c "alias artisan='php artisan'"
                fish -c "alias serve='php artisan serve'"
                fish -c "alias migrate='php artisan migrate'"
                fish -c "alias fresh='php artisan migrate:fresh --seed'"
                fish -c "alias tinker='php artisan tinker'"
                fish -c "alias wp='wp-cli'"
                fish -c "funcsave art artisan serve migrate fresh tinker wp"
              else
                # Bash/zsh aliases
                alias art="php artisan"
                alias artisan="php artisan"
                alias serve="php artisan serve"
                alias migrate="php artisan migrate"
                alias fresh="php artisan migrate:fresh --seed"
                alias tinker="php artisan tinker"
                alias wp="wp-cli"
              fi
              
              echo ""
              echo "Available tools:"
              echo "  - PHP with Composer"
              echo "  - Node.js with npm"
              echo "  - Laravel aliases: art, artisan, serve, migrate, fresh, tinker"
              echo "  - WordPress CLI alias: wp"
              echo ""
              echo "Quick start:"
              echo "  Laravel: composer create-project laravel/laravel project-name"
              echo "  WordPress: Download from wordpress.org or use composer"
            '';
          };
        };

    };
}
