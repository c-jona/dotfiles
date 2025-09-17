{ config, lib, pkgs, ... }:
let cfg = config.hardware.laptop;
in {
  options.hardware.laptop.enable = lib.mkEnableOption "laptop configuration";

  config = lib.mkIf cfg.enable {
    services = {
      acpid = {
        enable = true;
        lidEventCommands = ''
          args=($1)
          current=$(${pkgs.brightnessctl}/bin/brightnessctl --class=backlight get)
          case ''${args[2]} in
            close)
              if ((current != 0)); then
                ${pkgs.brightnessctl}/bin/brightnessctl --class=backlight --save set 0 >/dev/null
              fi
              ;;
            open)
              if ((current == 0)); then
                ${pkgs.brightnessctl}/bin/brightnessctl --class=backlight --restore >/dev/null
              fi
              ;;
          esac
        '';
      };
      logind.settings.Login = {
        HandleLidSwitch = "ignore";
        HandleLidSwitchDocked = "ignore";
      };
      thermald.enable = true;
      tlp.enable = true;
      udev.extraRules = ''
        SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", ATTR{capacity}=="[0-5]", RUN+="${pkgs.systemd}/bin/systemctl hibernate"
      '';
    };
  };
}
