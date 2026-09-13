# MacBook Air M4 — the daily driver.
{
  inputs,
  lib,
  ezModules,
  ...
}:

{
  imports = lib.attrValues ezModules;

  # Keep the existing machine name (ez-configs would default it to the
  # attribute name "macbook-air").
  networking.hostName = "budhilaw";
  networking.computerName = "budhilaw";

  system.stateVersion = 4;
  nixpkgs.hostPlatform = "aarch64-darwin";

  # nix-darwin's manual build trips on nixos-render-docs flags; we never read it.
  documentation.enable = false;
  # Builds a separate darwin-system just for the uninstaller; not needed with
  # Determinate Nix. Run `nix run nix-darwin#darwin-uninstaller` ad hoc if ever.
  system.tools.darwin-uninstaller.enable = false;

  environment.variables = {
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
  };

  # Secrets only this machine carries.
  home-manager.users.budhilaw = {
    within.gpg = {
      enable = true;
      privateKeys = {
        gpg_personal_key = "${inputs.self}/secrets/budhilaw-gpg.yaml";
        gpg_amartha_key = "${inputs.self}/secrets/amartha-gpg.yaml";
      };
      trustKeyIds = [
        "0xBD838B746BAA8C5F"
        "0x32B604FD91055131"
      ];
    };
    within.ssh = {
      sopsFile = "${inputs.self}/secrets/budhilaw-ssh.yaml";
      privateKeys = [
        "id_ed25519_personal"
        "id_ed25519_hosthatch"
        "id_ed25519_hosthatch_deploy"
        "id_ed25519_hosthatch_deploy_agent"
        "id_ed25519_amartha"
        "id_ed25519_cloudnan_deploy"
      ];
    };
  };

  # iTerm2 default profile ("New Bookmarks:0"). These are nested array
  # entries, which `defaults write` cannot address, so PlistBuddy it is.
  # Runs as root against the user's plist; in-place edits keep ownership.
  system.activationScripts.postActivation.text = ''
    itermPlist="/Users/budhilaw/Library/Preferences/com.googlecode.iterm2.plist"
    if [ -f "$itermPlist" ]; then
      /usr/libexec/PlistBuddy \
        -c "Set ':New Bookmarks:0:Columns' 110" \
        -c "Set ':New Bookmarks:0:Rows' 35" \
        -c "Set ':New Bookmarks:0:Character Encoding' 4" \
        -c "Set ':New Bookmarks:0:Normal Font' 'CaskaydiaMonoNF-Regular 14'" \
        -c "Set ':New Bookmarks:0:Non Ascii Font' 'CaskaydiaMonoNF-Regular 14'" \
        -c "Set ':New Bookmarks:0:Window Type' 12" \
        -c "Set ':New Bookmarks:0:Transparency' 0.15" \
        -c "Set ':New Bookmarks:0:Blur' 1" \
        -c "Set ':New Bookmarks:0:Blur Radius' 5" \
        "$itermPlist" 2>/dev/null || true
      for kv in "Set Local Environment Vars|integer|2" "Custom Locale|string|en_US.UTF-8" "Show Mark Indicators|bool|false"; do
        IFS='|' read -r key type value <<< "$kv"
        /usr/libexec/PlistBuddy -c "Delete ':New Bookmarks:0:$key'" "$itermPlist" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Add ':New Bookmarks:0:$key' $type '$value'" "$itermPlist" 2>/dev/null || true
      done
      # Natural Text Editing keybindings. PlistBuddy on macOS 26 aborts when
      # given more than ~14 -c commands at once, so one binding per call.
      /usr/libexec/PlistBuddy -c "Delete ':New Bookmarks:0:Keyboard Map'" "$itermPlist" 2>/dev/null || true
      /usr/libexec/PlistBuddy -c "Add ':New Bookmarks:0:Keyboard Map' dict" "$itermPlist" 2>/dev/null || true
      printf '%s\n' \
        '0x7f-0x80000|11|0x1b 0x7f' \
        '0x7f-0x100000|11|0x15' \
        '0xf702-0x280000|10|b' \
        '0xf702-0x300000|11|0x1' \
        '0xf703-0x280000|10|f' \
        '0xf703-0x300000|11|0x5' \
        '0xf728-0x0|11|0x4' \
        '0xf728-0x80000|10|d' \
      | while IFS='|' read -r key action text; do
        /usr/libexec/PlistBuddy \
          -c "Add ':New Bookmarks:0:Keyboard Map:$key' dict" \
          -c "Add ':New Bookmarks:0:Keyboard Map:$key:Action' integer $action" \
          -c "Add ':New Bookmarks:0:Keyboard Map:$key:Text' string '$text'" \
          "$itermPlist" 2>/dev/null || true
      done
    fi
  '';
}
