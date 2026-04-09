{ pkgs, lib, ... }:

let
  budhilaw = {
    name = "Ericsson Budhilaw";
    email = "ericsson@budhilaw.com";
    signingKey = "0xBD838B746BAA8C5F";
  };
in
{
  programs.git = {
    enable = true;
    ignores = [
      ".DS_Store"
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
      };
      init.defaultBranch = "main";
      
      # Multiple GitHub accounts configuration
      includeIf = {
        "gitdir:~/.config/nixverse/" = {
          path = "~/.gitconfig-personal";
        };
        "gitdir:~/Dev/Personal/" = {
          path = "~/.gitconfig-personal";
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
}
