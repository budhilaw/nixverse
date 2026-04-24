{ pkgs, lib, ... }:

let
  budhilaw = {
    name = "Ericsson Budhilaw";
    email = "ericsson@budhilaw.com";
    signingKey = "0xBD838B746BAA8C5F";
  };
  amartha = {
    name = "Ericsson Budhilaw";
    email = "ericsson.budhilaw@amartha.com";
    signingKey = "0x32B604FD91055131";
  };
in
{
  programs.git = {
    enable = true;
    ignores = [
      ".DS_Store"
      ".direnv"
    ];

    settings = {
      gpg = {
        program = "${pkgs.gnupg}/bin/gpg2";
      };
      rerere.enable = true;
      commit.gpgSign = true;
      pull.ff = "only";
      diff.tool = "code";
      difftool.prompt = false;
      merge.tool = "code";
      url = {
        "git@github.com:" = {
          insteadOf = "https://github.com/";
        };
        "git@bitbucket.org:" = {
          insteadOf = "https://bitbucket.org/";
        };
      };
      init.defaultBranch = "main";
      
      # Multiple identities — selected by working directory
      includeIf = {
        "gitdir:~/.config/nixverse/" = {
          path = "~/.gitconfig-personal";
        };
        "gitdir:~/Dev/Personal/" = {
          path = "~/.gitconfig-personal";
        };
        "gitdir:~/Dev/Amartha/" = {
          path = "~/.gitconfig-amartha";
        };
      };
    };
  };

  # Config for personal account (default)
  home.file.".gitconfig-personal".text = ''
    [user]
      name = ${budhilaw.name}
      email = ${budhilaw.email}
      signingKey = ${budhilaw.signingKey}
  '';

  # Config for Amartha account (active inside ~/Dev/Amartha/)
  home.file.".gitconfig-amartha".text = ''
    [user]
      name = ${amartha.name}
      email = ${amartha.email}
      signingKey = ${amartha.signingKey}
  '';

  ### git tools
  ## github cli
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      aliases = {
        co = "pr checkout";
        pv = "pr view";
      };
    };
  };

  home.packages = [ pkgs.git-filter-repo ];

  # Remove any rogue ~/.gitconfig that would override ~/.config/git/config.
  # Git reads ~/.gitconfig last at user scope, so a stray file there silently
  # overrides the nix-managed config (e.g. email set by GUI tools, iCloud sync).
  home.activation.removeRogueGitconfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    if [ -e "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then
      rm -f "$HOME/.gitconfig"
    fi
  '';
}
