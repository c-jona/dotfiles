{ config, lib, pkgs, ... }:
let cfg = config.services.greetd;
in lib.mkMerge [
  {
    services.greetd.settings.default_session.command = "tuigreet --asterisks --remember --remember-user-session --time --time-format '%A, %d %B %Y - %H:%M:%S' --user-menu --width 55 --window-padding 1 --xsession-wrapper '>/dev/null 2>&1 startx /usr/bin/env ${config.services.displayManager.sessionData.wrapper}'";
  }
  (lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.tuigreet ];

    services.xserver.displayManager.startx.enable = true;
  })
]
