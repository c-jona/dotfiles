{ config, lib, pkgs, ... }:
let cfg = config.services.enable-numlock;
in {
  options.services.enable-numlock.enable = lib.mkEnableOption "enable-numlock";

  config = lib.mkIf cfg.enable {
    systemd.services.enable-numlock = {
      description = "enable numlock on TTYs";
      script = ''
        for tty in /dev/tty{1..6}; do
          ${pkgs.kbd}/bin/setleds -D +num < $tty
        done
      '';
      serviceConfig = {
        RemainAfterExit = true;
        StandardInput = "tty";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
