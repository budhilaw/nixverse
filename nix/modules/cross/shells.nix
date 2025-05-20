{ pkgs, config, ... }:

{
  # Add shells installed by nix to /etc/shells file
  environment = with pkgs; {
    shells = [ fish ];

    variables = {
      SHELL = "${fish}/bin/fish";
      CC = "${gcc}/bin/gcc";
    };

    # Add babelfish to system packages
    systemPackages = [ pkgs.babelfish ];
  };

  # Make Fish the default shell
  programs = {
    fish.enable = true;
    # Needed to address bug where $PATH is not properly set for fish
    fish.shellInit = # fish
      ''
        for p in (string split : $PATH)
          if not contains $p $fish_user_paths
            set -g fish_user_paths $fish_user_paths $p
          end
        end
      '';
  };
}
