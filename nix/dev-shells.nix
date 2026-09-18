# `nix develop ~/.config/nixverse#<name>` (or the `nd <name>` fish function).
{
  perSystem =
    { pkgs, config, ... }:
    let
      goShell =
        {
          go,
          extra ? [ ],
          hook ? "",
        }:
        pkgs.mkShell {
          nativeBuildInputs = [
            go
            pkgs.gopls
            pkgs.go-tools
            pkgs.delve
            pkgs.golangci-lint
          ]
          ++ extra;
          shellHook = ''
            export GOPATH="$(${go}/bin/go env GOPATH)"
            export PATH="$GOPATH/bin:$PATH"
            ${hook}
          '';
        };

      # Node from the stable release so binaries always come from the cache.
      # pnpm is the only package manager here. Its content-addressable store
      # hardlinks every dependency, so a node_modules costs close to nothing
      # on disk; keeping yarn/npm around would just reintroduce duplicate
      # per-project trees.
      nodeShell =
        node:
        pkgs.mkShell {
          nativeBuildInputs = [
            node
            pkgs.stable.pnpm
            # node-gyp needs distutils, gone from Python 3.12+
            (pkgs.python3.withPackages (ps: [ ps.setuptools ]))
            pkgs.pkg-config
          ];
        };

      pythonShell =
        py:
        pkgs.mkShell {
          nativeBuildInputs = [
            py
            pkgs.uv
            pkgs.ruff
          ]
          ++ (with py.pkgs; [
            pip
            virtualenv
            pytest
            ipython
            mypy
          ]);
        };

      grpc = with pkgs; [
        protobuf
        protoc-gen-go
        protoc-gen-go-grpc
      ];

      amarthaHook = ''
        export GOBIN="$PWD/bin"
        export PATH="$GOBIN:$PATH"
        export GOPRIVATE=bitbucket.org/Amartha
      '';
    in
    {
      pre-commit.check.enable = true;
      pre-commit.settings.hooks = {
        nixfmt.enable = true;
        deadnix.enable = true;
      };

      devShells = {
        # Working on nixverse itself.
        default = pkgs.mkShell {
          shellHook = config.pre-commit.installationScript;
          packages = with pkgs; [
            nixfmt
            deadnix
            sops
            age
            ssh-to-age
            nixos-anywhere
          ];
        };

        ## Go
        go = goShell {
          go = pkgs.go;
          extra =
            with pkgs;
            [
              go-migrate
              go-mockery
            ]
            ++ grpc;
        };
        goService = goShell {
          go = pkgs.go_1_25;
          extra = grpc;
          hook = amarthaHook;
        };
        goAgent = goShell {
          go = pkgs.go_1_25;
          extra = grpc;
          hook = amarthaHook;
        };
        # Sudutkelasku backend
        carikelas = goShell {
          go = pkgs.go;
          extra = with pkgs; [
            goose
            stable.k6
          ];
        };
        # budhilaw.com API
        budhilaw = goShell {
          go = pkgs.go_1_25;
          extra = with pkgs; [
            sqlc
            goose
            postgresql_16
          ];
        };

        ## Node
        nodejs = nodeShell pkgs.stable.nodejs_24;
        nodejs24 = nodeShell pkgs.stable.nodejs_24;
        nodejs22 = nodeShell pkgs.stable.nodejs_22;
        nodejs20 = nodeShell pkgs.stable.nodejs_20;
        webApp = nodeShell pkgs.stable.nodejs_24;
        carikelasWeb = nodeShell pkgs.stable.nodejs_24;
        budhilawWeb = nodeShell pkgs.stable.nodejs_24;

        ## Python
        python = pythonShell pkgs.python3;
        python313 = pythonShell pkgs.python313;
        python312 = pythonShell pkgs.python312;

        ## Rust
        rust = pkgs.mkShell {
          RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
          nativeBuildInputs = with pkgs; [
            rustup
            rustc
            cargo
            rustfmt
            clippy
            pkg-config
          ];
          shellHook = ''export PATH="$PATH:$HOME/.cargo/bin"'';
        };

        ## Java (Flink jobs)
        java = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            jdk17
            maven
          ];
          JAVA_HOME = pkgs.jdk17.home;
        };

        ## PHP (Laravel / WordPress)
        php = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            php
            php84Packages.composer
            stable.nodejs_24
            wp-cli
          ];
          shellHook = ''export PATH="$PATH:$HOME/.composer/vendor/bin"'';
        };
      };
    };
}
