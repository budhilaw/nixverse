{
  inputs,
  lib,
  pkgs,
  ezModules,
  osConfig,
  ...
}:

{
  home = rec {
    username = "budhilaw";
    stateVersion = "24.11";
    homeDirectory = osConfig.users.users.${username}.home;
    # sessionVariables.EDITOR = lib.getExe' inputs.self.packages.${pkgs.stdenv.system}.nvim "nvim";
  };

  within = {
    gpg.enable = true;
  };

  imports = lib.attrValues ezModules ++ [
    # --- secrets
    inputs.sops-nix.homeManagerModules.sops
    {
      sops.gnupg.home = "~/.gnupg";
      # sops.gnupg.sshKeyPaths = [ ];
      # sops.defaultSopsFile = "${inputs.self}/secrets/secret.yaml";
      # sops.secrets.openai_api_key.path = "%r/openai_api_key";
      # sops.secrets.codeium.path = "%r/codeium";
      programs.git.extraConfig.diff.sopsdiffer.textconv = "sops -d --config /dev/null";
      home.packages = [ pkgs.sops ];
    }
    # --- secrets
  ];

}
