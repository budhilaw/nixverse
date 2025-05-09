{ pkgs, lib, ... }:

let
  budhilaw = {
    name = "Ericsson Budhilaw";
    email = "ericsson@budhilaw.com";
    signingKey = "0x936C2C581A15BB64";
  };

  ericharsya = {
    name = "Ericsson Budhilaw";
    email = "ericsson.budhilaw@paper.id";
    signingKey = "0x3AFAE7E10542D24E";
  };
in
{
  programs.git = {
    enable = true;
    ignores = [
      ".DS_Store"
    ];

    extraConfig = {
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
        
        # Specific rule for Paper organization repositories
        "git@github.com-paper:paper-indonesia/" = {
          insteadOf = "https://github.com/paper-indonesia/";
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
        "gitdir:~/Dev/Paper/" = {
          path = "~/.gitconfig-paper";
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

  # Config for paper/work account
  home.file.".gitconfig-paper".text = ''
    [user]
      name = ${ericharsya.name}
      email = ${ericharsya.email}
      signingKey = ${ericharsya.signingKey}
  '';

  # SSH config for multiple GitHub accounts
  home.file.".ssh/config".text = ''
    Host *
        UseKeychain yes

    Host github.com
      HostName github.com
      User git
      IdentityFile ~/.ssh/id_ed25519_personal
      IdentitiesOnly yes
      
    Host github.com-paper
      HostName github.com
      User git
      IdentityFile ~/.ssh/id_ed25519_paper
      IdentitiesOnly yes
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
