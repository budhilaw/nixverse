# Age key lives in 1Password; restore it to ~/.config/sops/age/keys.txt on a
# new machine before the first rebuild.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  # sops-nix's own darwin activation step runs `launchctl bootstrap` on
  # ~/Library/LaunchAgents/org.nix-community.home.sops-nix.plist with no DAG
  # ordering against home-manager's setupLaunchAgents, which is what copies
  # that plist into place. On a fresh machine the plist isn't there yet, so
  # launchctl fails with "Bootstrap failed: 5: Input/output error" and aborts
  # the rest of activation. setupLaunchAgents already bootstraps the agent
  # (RunAtLoad runs the decrypt script), so all we need is to re-kick it after.
  home.activation.sops-nix = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
    lib.mkForce (
      lib.hm.dag.entryAfter [ "setupLaunchAgents" ] ''
        /bin/launchctl kickstart -k "gui/$(id -u)/org.nix-community.home.sops-nix" || true
      ''
    )
  );

  home.packages = [
    pkgs.sops
    pkgs.age
  ];

  programs.git.settings.diff.sopsdiffer.textconv = "sops -d --config /dev/null";
}
