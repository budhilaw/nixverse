# Determinate Nix owns the daemon and /etc/nix/nix.conf on this Mac.
# nix-darwin's own nix.* settings are inert in that setup, so custom settings
# go through this module, which writes /etc/nix/nix.custom.conf.
{ inputs, ... }:

{
  imports = [ inputs.determinate.darwinModules.default ];

  determinateNix = {
    enable = true;
    customSettings = {
      trusted-users = [
        "root"
        "budhilaw"
      ];
      extra-substituters = [
        "https://budhilaw.cachix.org"
        "https://nix-community.cachix.org"
      ];
      extra-trusted-public-keys = [
        "budhilaw.cachix.org-1:Fbyz4CIpkeY0n6XkK3v2lznxqAvA+vGBJGHBahaI53A="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    # Native Linux builder (macOS Virtualization.framework). Flip to "enabled"
    # once Determinate has rolled it out to this account; it lets the Mac build
    # x86_64-linux closures for the homelab.
    determinateNixd.builder.state = "disabled";
  };
}
