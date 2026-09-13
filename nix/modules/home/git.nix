{ pkgs, lib, ... }:

let
  personal = {
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
      # Personal identity by default; work identity inside ~/Dev/Amartha/.
      user = personal;
      gpg.program = "${pkgs.gnupg}/bin/gpg2";
      commit.gpgSign = true;
      rerere.enable = true;
      pull.ff = "only";
      init.defaultBranch = "main";
      diff.tool = "code";
      difftool.prompt = false;
      merge.tool = "code";
      url = {
        "git@github.com:".insteadOf = "https://github.com/";
        "git@bitbucket.org:".insteadOf = "https://bitbucket.org/";
      };
    };

    includes = [
      {
        condition = "gitdir:~/Dev/Amartha/";
        contents.user = amartha;
      }
    ];
  };

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

  # Git reads ~/.gitconfig after ~/.config/git/config, so a stray file there
  # (written by a GUI tool, synced by iCloud) silently overrides this config.
  home.activation.removeRogueGitconfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    if [ -e "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then
      rm -f "$HOME/.gitconfig"
    fi
  '';
}
