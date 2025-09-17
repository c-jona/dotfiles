{ config, lib, pkgs, ... }:
let cfg = config.services.gnome.polkit-agent;
in {
  options.services.gnome.polkit-agent.enable = lib.mkEnableOption "polkit GNOME authentication agent";

  config = lib.mkIf cfg.enable {
    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      after = [ "graphical-session.target" ];
      description = "polkit GNOME authentication agent";
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "always";
        RestartSec = 3;
      };
      wantedBy = [ "graphical-session.target" ];
    };
  };
}
