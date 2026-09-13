# Weekly garbage collection. nix-darwin's nix.gc is inert under Determinate
# Nix, so old darwin-system generations (and the app versions they pin) would
# otherwise pile up forever. Runs Sunday 03:00 as root.
{
  launchd.daemons.nix-gc.serviceConfig = {
    ProgramArguments = [
      "/nix/var/nix/profiles/default/bin/nix-collect-garbage"
      "--delete-older-than"
      "30d"
    ];
    StartCalendarInterval = [
      {
        Weekday = 0;
        Hour = 3;
        Minute = 0;
      }
    ];
    StandardOutPath = "/var/log/nix-gc.log";
    StandardErrorPath = "/var/log/nix-gc.log";
  };
}
