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
              # Use stable nixpkgs for NodeJS to guarantee binary cache hits.
              # nixpkgs-unstable packages may not be cached yet on Hydra for
              # the current commit, causing full rebuilds from source.
              node = pkgs.branches.stable.${name};
            in
            pkgs.mkShell {
              description = "${name} Development Environment";
              buildInputs = [
                node
                pkgs.branches.stable.yarn
                pkgs.branches.stable.pnpm
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
            nativeBuildInputs = with pkgs.branches.stable; [
              nodejs_24
              yarn
              pnpm
            ] ++ (with pkgs; [
              # node-gyp requires Python with distutils (removed in Python 3.12+)
              (python3.withPackages (ps: [ ps.setuptools ]))
              pkg-config
            ]);
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
            description = "Python latest";
            nativeBuildInputs = with pkgs; [
              python3
              uv
              ruff
              python3Packages.pip
              python3Packages.virtualenv
              python3Packages.setuptools
              python3Packages.wheel
              python3Packages.pytest
              python3Packages.ipython
              python3Packages.mypy
            ];
            shellHook = ''
              echo "Python $(python --version | cut -d' ' -f2)"
              echo "Tools: uv, ruff, pip, virtualenv, pytest, mypy, ipython"
            '';
          };

          python313 = pkgs.mkShell {
            description = "Python 3.13";
            nativeBuildInputs = with pkgs; [
              python313
              uv
              ruff
              python313Packages.pip
              python313Packages.virtualenv
              python313Packages.pytest
              python313Packages.ipython
            ];
          };

          python312 = pkgs.mkShell {
            description = "Python 3.12";
            nativeBuildInputs = with pkgs; [
              python312
              uv
              ruff
              python312Packages.pip
              python312Packages.virtualenv
              python312Packages.pytest
              python312Packages.ipython
            ];
          };

          python311 = pkgs.mkShell {
            description = "Python 3.11";
            nativeBuildInputs = with pkgs; [
              python311
              uv
              ruff
              python311Packages.pip
              python311Packages.virtualenv
              python311Packages.pytest
              python311Packages.ipython
            ];
          };

          #
          #
          #    $ nix develop github:budhilaw/nixverse#phpdev
          #
          #
          #
          #    Go service — Go 1.25 backend with gRPC tooling
          #    $ nix develop ~/.config/nixverse#goService
          #
          goService = pkgs.mkShell {
            description = "Go 1.25 service (gRPC + linters)";
            nativeBuildInputs = with pkgs; [
              go_1_25
              gopls
              go-tools
              branches.master.golangci-lint
              protobuf
              protoc-gen-go
              protoc-gen-go-grpc
            ];
            shellHook = ''
              export GOBIN="$PWD/bin"
              export GOPATH="$(${pkgs.go_1_25}/bin/go env GOPATH)"
              export PATH="$GOBIN:$GOPATH/bin:$PATH"
              git config --global --add url."git@bitbucket.org:".insteadOf "https://bitbucket.org/" 2>/dev/null || true
              export GOPRIVATE=bitbucket.org/Amartha
            '';
          };

          #
          #    Go agent — Go 1.23 binary with gRPC, no DB
          #    $ nix develop ~/.config/nixverse#goAgent
          #
          goAgent = pkgs.mkShell {
            description = "Go 1.25 agent/binary (gRPC, no DB)";
            nativeBuildInputs = with pkgs; [
              go_1_25
              gopls
              go-tools
              branches.master.golangci-lint
              protobuf
              protoc-gen-go
              protoc-gen-go-grpc
            ];
            shellHook = ''
              export GOBIN="$PWD/bin"
              export GOPATH="$(${pkgs.go_1_25}/bin/go env GOPATH)"
              export PATH="$GOBIN:$GOPATH/bin:$PATH"
              git config --global --add url."git@bitbucket.org:".insteadOf "https://bitbucket.org/" 2>/dev/null || true
              export GOPRIVATE=bitbucket.org/Amartha
            '';
          };

          #
          #    Web app — Node 24 + yarn + pnpm for SPA / Vite / Next
          #    $ nix develop ~/.config/nixverse#webApp
          #
          webApp = pkgs.mkShell {
            description = "Node.js 24 web app (yarn + pnpm)";
            nativeBuildInputs = with pkgs.branches.stable; [
              nodejs_24
              yarn
              pnpm
            ];
          };

          #
          #    Sudutkelasku (carikelas) backend — Go + goose migrations + K6
          #    $ nix develop ~/.config/nixverse#carikelas
          #
          carikelas = pkgs.mkShell {
            description = "Sudutkelasku backend (Go + goose + K6)";
            # NOTE: `pkgs.go` must be qualified. A bare `go` here would resolve
            # to the `go` devShell defined in this same `rec { ... }` block
            # (whose mkShell marker file then gets sourced and fails), not the
            # Go toolchain.
            nativeBuildInputs = [
              pkgs.go
              pkgs.gopls
              # stable branch: on nixpkgs-weekly the bare `goose` attribute
              # resolves to the AI agent, not the DB migration tool.
              pkgs.branches.stable.goose
              pkgs.branches.stable.k6
            ];
            shellHook = ''
              export GOPATH="$(${pkgs.go}/bin/go env GOPATH)"
              export PATH="$GOPATH/bin:$PATH"
            '';
          };

          #
          #    Sudutkelasku (carikelas) frontend — Node.js 24
          #    $ nix develop ~/.config/nixverse#carikelasWeb
          #
          carikelasWeb = pkgs.mkShell {
            description = "Sudutkelasku frontend (Node.js 24)";
            nativeBuildInputs = with pkgs.branches.stable; [
              nodejs_24
              yarn
              pnpm
            ] ++ (with pkgs; [
              (python3.withPackages (ps: [ ps.setuptools ]))
              pkg-config
            ]);
          };

          #
          #    Java — JDK 17 + Maven (Flink jobs)
          #    $ nix develop ~/.config/nixverse#java
          #
          java = pkgs.mkShell {
            description = "Java 17 + Maven (Flink) Development Environment";
            nativeBuildInputs = with pkgs; [
              jdk17
              maven
            ];
            shellHook = ''
              export JAVA_HOME="${pkgs.jdk17.home}"
              export PATH="$JAVA_HOME/bin:$PATH"
              echo "Java Development Environment"
              echo "Java version: $(java -version 2>&1 | head -n1)"
              echo "Maven version: $(mvn -v 2>/dev/null | head -n1)"
            '';
          };

          phpdev = pkgs.mkShell {
            description = "PHP Development Environment for Laravel & WordPress";
            nativeBuildInputs = with pkgs; [
              php
              php84Packages.composer
              branches.stable.nodejs_24
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
