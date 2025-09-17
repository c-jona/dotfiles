{ config, lib, pkgs, ... }:
let cfg = config.services.pipewire;
in lib.mkMerge [
  {
    services.pipewire = {
      alsa.enable = true;
      jack.enable = true;
      pulse.enable = true;
    };
  }
  (lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.pulseaudio ];

    security.rtkit.enable = true;
  })
]
