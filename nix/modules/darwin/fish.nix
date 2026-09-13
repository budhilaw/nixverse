{ pkgs, ... }:

{
  environment.shells = [ pkgs.fish ];

  programs.fish = {
    enable = true;
    # macOS path_helper reorders PATH for login shells; re-add everything so
    # Nix paths keep priority in fish.
    shellInit = # fish
      ''
        for p in (string split : $PATH)
          if not contains $p $fish_user_paths
            set -g fish_user_paths $fish_user_paths $p
          end
        end
      '';
  };
}
