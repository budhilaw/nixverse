{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  nixverse = "~/.config/nixverse";
  # Flake attribute for this machine (`drs`/`nrs` rebuild it). Defaults to the
  # hostname; hosts whose attribute name differs set within.host explicitly.
  host = config.within.host;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;

  # gdb/gdbr/gdt/gdtr <days>: delete branches/tags older than N days.
  gitPrune =
    let
      cmd =
        sortKey: ref: action: # bash
        ''
          set -e
          [ -z "$1" ] && echo "usage: $(basename "$0") <days>" && exit 1
          threshold=$(date -v-"$1"d +%s 2>/dev/null || date -d "$1 days ago" +%s)
          ${pkgs.git}/bin/git for-each-ref --sort=${sortKey} --format '%(refname:short) %(${sortKey}:unix)' "${ref}" \
          | while read -r name when; do
            if [ -n "$when" ] && [ "$when" -lt "$threshold" ]; then
              echo "==> $name is older than $1 days, deleting"
              ${action} "$name"
            fi
          done
        '';
    in
    {
      gdb = pkgs.writeShellScriptBin "gdb" (cmd "committerdate" "refs/heads" "git branch -D");
      gdbr = pkgs.writeShellScriptBin "gdbr" (
        cmd "committerdate" "refs/remotes/origin" "git push origin -d"
      );
      gdt = pkgs.writeShellScriptBin "gdt" (cmd "taggerdate" "refs/tags" "git tag -d");
      gdtr = pkgs.writeShellScriptBin "gdtr" (cmd "taggerdate" "refs/tags" "git push origin -d");
    };

  shellAliases = {
    # nixverse
    flakeup-all = "nix flake update --flake ${nixverse}";
    flakeup = "nix flake update --flake ${nixverse}"; # flakeup nixpkgs
    nclean = "sudo nix-collect-garbage --delete-older-than 30d && nix store optimise";
    nb = "nix build";
    ndp = "nix develop";
    nf = "nix flake";
    nr = "nix run";
    ns = "nix-shell";
    nq = "nix search";
    da = "direnv allow";
    dr = "direnv reload";

    # gpg backup/restore
    gpbs = "gpg --export-options backup --export-secret-keys";
    gpbp = "gpg --export-options backup --export";
    gprs = "gpg --export-options restore --import";
    gpbt = "gpg --export-ownertrust";
    gprt = "gpg --import-ownertrust";

    # shell
    grep = "${pkgs.ripgrep}/bin/rg";
    cat = "${pkgs.bat}/bin/bat";
    du = "${pkgs.dust}/bin/dust";
    c = "z";
    cc = "zi";
    rm = "rm -i";
    p = "ping";
    l = "ls -l";
    la = "ls -a";
    lla = "ls -la";

    # git
    g = "git";
    pullhead = "git pull origin (git rev-parse --abbrev-ref HEAD)";
    pushhead = "git push origin (git rev-parse --abbrev-ref HEAD)";
    beda = "git diff";
    ingfo = "git status";
    tarek = "pullhead";
    gas = "pushhead";
    gasin = "pushhead --force";
    gtmp = "git commit -m \"temp\" --no-verify";
    gf = "git flow";
    gl = "git log --graph --oneline --all";
    gll = "git log --oneline --decorate --all --graph --stat";
    gld = "git log --oneline --all --pretty=format:\"%h%x09%an%x09%ad%x09%s\"";
    gls = "gl --show-signature";
    gfa = "git fetch --all";
    grc = "git rebase --continue";
    gri = "git rebase --interactive";
  }
  // lib.optionalAttrs isDarwin {
    drb = "darwin-rebuild build --flake ${nixverse}#${host}";
    drs = "sudo darwin-rebuild switch --flake ${nixverse}#${host}";
  }
  // lib.optionalAttrs isLinux {
    nrb = "nixos-rebuild build --flake ${nixverse}#${host}";
    nrs = "sudo nixos-rebuild switch --flake ${nixverse}#${host}";
  };
in
{
  options.within.host = lib.mkOption {
    type = lib.types.str;
    default = osConfig.networking.hostName;
    description = "Flake output name of this machine, used by the rebuild aliases.";
  };

  config.home = {
    inherit shellAliases;
    sessionPath = [ "$HOME/.yarn/bin" ];
    packages = [
      pkgs.babelfish
      pkgs.fishPlugins.colored-man-pages
      pkgs.fishPlugins.done
    ]
    ++ lib.attrValues gitPrune;
  };

  config.programs = {
    atuin = {
      enable = true;
      enableFishIntegration = config.programs.fish.enable;
      enableBashIntegration = config.programs.bash.enable;
    };

    zoxide = {
      enable = true;
      enableFishIntegration = config.programs.fish.enable;
    };

    dircolors = {
      enable = true;
      enableFishIntegration = config.programs.fish.enable;
    };

    bash = {
      enable = true;
      enableCompletion = true;
    };

    fish = {
      enable = true;

      functions = {
        ghds = ''
          for repo in $argv
            gh repo delete $repo --yes
          end
        '';
        gitignore = "curl -sL https://www.gitignore.io/api/$argv";
        nd = "nix develop ${nixverse}#$argv[1] -c $SHELL";
        rpkgjson = ''
          ${pkgs.nodejs}/bin/node -e "console.log(Object.entries(require('./package.json').$argv[1]).map(([k,v]) => k.concat(\"@\").concat(v)).join(\"\n\") )"
        '';
      };

      interactiveShellInit = ''
        fish_add_path -g ~/.local/bin

        set -gx LANG en_US.UTF-8
        set -gx LC_ALL en_US.UTF-8

        set -U fish_color_command 6CB6EB --bold
        set -U fish_color_redirection DEB974
        set -U fish_color_operator DEB974
        set -U fish_color_end C071D8 --bold
        set -U fish_color_error EC7279 --bold
        set -U fish_color_param 6CB6EB
        set fish_greeting
      '';
    };

    starship = {
      enable = true;
      enableFishIntegration = config.programs.fish.enable;
      enableBashIntegration = config.programs.bash.enable;
      enableTransience = config.programs.fish.enable;
      settings =
        let
          withStartLineBreak = s: " ${s}";
          withEndLineBreak = s: "${s} ";
          defaultProgramFormat = withEndLineBreak "[$symbol($version)]($style)";
        in
        {
          add_newline = true;
          command_timeout = 1000;

          cmd_duration = {
            format = withStartLineBreak "[$duration]($style)";
            style = "bold #EC7279";
            show_notifications = true;
          };

          battery = {
            full_symbol = "🔋 ";
            charging_symbol = "⚡️ ";
            discharging_symbol = "💀 ";
          };

          bun.format = defaultProgramFormat;
          git_branch.format = withEndLineBreak "[$symbol$branch]($style)";
          git_status.format = withEndLineBreak "([$all_status$ahead_behind]($style))";
          gcloud.format = withEndLineBreak "[$symbol$active]($style)";
          golang.format = defaultProgramFormat;
          nix_shell.symbol = "❄️";
          nix_shell.format = withEndLineBreak "[$symbol$state]($style)";
          nix_shell.impure_msg = "󰊰";
          nix_shell.pure_msg = "󱨧";
          nodejs.format = defaultProgramFormat;
          ocaml.format = withEndLineBreak "[$symbol($version)(\($switch_indicator$switch_name\))]($style)";
          package.format = withEndLineBreak "[$symbol$version]($style)";
          rust.format = defaultProgramFormat;
          zig.format = defaultProgramFormat;
        };
    };
  };
}
