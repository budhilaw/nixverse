{ pkgs, lib, ... }:

let
  budhilaw = {
    name = "Ericsson Budhilaw";
    email = "ericsson@budhilaw.com";
    signingKey = "0x936C2C581A15BB64";
  };

  ericharsya = {
    name = "Ericsson Budhilaw";
    email = "ericsson.budhilaw@harsya.com";
    signingKey = "0x936C2C581A15BB64";
  };
in
{
  programs.git = {
    enable = true;
    userName = budhilaw.name;
    userEmail = budhilaw.email;
    signing = {
      key = budhilaw.signingKey;
      signByDefault = true;
    };

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
      };
      init.defaultBranch = "main";
      
      # Multiple GitHub accounts configuration
      includeIf = {
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
    # Default GitHub config
    Host github.com
      HostName github.com
      User git
      # Automatically detect which key to use
      IdentityFile ~/.ssh/id_ed25519_personal
      IdentityFile ~/.ssh/id_ed25519_paper
      
    # Explicit config for personal projects
    Host github.com-personal
      HostName github.com
      User git
      IdentityFile ~/.ssh/id_ed25519_personal
      IdentitiesOnly yes
      
    # Explicit config for paper projects  
    Host github.com-paper
      HostName github.com
      User git
      IdentityFile ~/.ssh/id_ed25519_paper
      IdentitiesOnly yes
      
    # GitHub pattern matching for Paper organization repos
    Host github.com
      HostName github.com
      User git
      IdentityFile ~/.ssh/id_ed25519_paper
      IdentitiesOnly yes
      Match host github.com exec "echo %h | grep -q 'paper-indonesia'"
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
