{ config, lib, pkgs, ... }:
let
  scripts = pkgs.symlinkJoin {
    name = "brightness-scripts";
    paths = builtins.attrValues (
      let
        brightness_env_setup = pkgs.writeText "brightness_env_setup" ''
          command='${pkgs.brightnessctl}/bin/brightnessctl --class=backlight --exponent=${toString cfg.exponent} --min-value=1 --machine-readable'
          interval=${toString cfg.interval}
          min_pct=${toString cfg.minBrightness}
          IFS=, read device _ _ current_pct max < <($command info)
          current_pct=''${current_pct%\%}
        '';
      in builtins.mapAttrs pkgs.writeShellScriptBin {
        get-brightness-device = ''
          . ${brightness_env_setup}
          echo $device
        '';
        get-brightness = ''
          . ${brightness_env_setup}
          echo $current_pct
        '';
        decrease-brightness = ''
          . ${brightness_env_setup}
          if ((current_pct > min_pct)); then
            new_pct=$((current_pct - (current_pct % $interval == 0 ? $interval : current_pct % $interval)))
            $command set $((new_pct > min_pct ? new_pct : min_pct))% >/dev/null
          fi
        '';
        increase-brightness = ''
          . ${brightness_env_setup}
          if ((current_pct < 100)); then
            $command set $((current_pct + $interval - (current_pct % $interval)))% >/dev/null
          fi
        '';
        set-brightness = ''
          (($# < 1)) && exit 1
          . ${brightness_env_setup}
          $command set $(($1 > min_pct ? $1 : min_pct))% >/dev/null
        '';
      }
    );
  };

  cfg = config.hardware.brightness-controls;
in {
  options.hardware.brightness-controls = {
    enable = lib.mkEnableOption "brightness-controls";
    exponent = lib.mkOption {
      default = 1.25;
      description = "exponent for brightness changes";
      type = lib.types.number;
    };
    interval = lib.mkOption {
      default = 10;
      description = "interval for brightness changes in %";
      type = lib.types.ints.between 1 100;
    };
    minBrightness = lib.mkOption {
      default = 1;
      description = "minimum brightness level in %";
      type = lib.types.ints.between 1 100;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.brightnessctl scripts ];

    services = {
      acpid = {
        enable = true;
        handlers = {
          brightnessDownEvent = {
            action = "${scripts}/bin/decrease-brightness";
            event = "video/brightnessdown.*";
          };
          brightnessUpEvent = {
            action = "${scripts}/bin/increase-brightness";
            event = "video/brightnessup.*";
          };
        };
      };
      udev.extraRules = ''
        SUBSYSTEM=="backlight", ENV{ID_BACKLIGHT_CLAMP}="0"
      '';
    };
  };
}
