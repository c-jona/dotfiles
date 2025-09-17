{ config, lib, pkgs, ... }:
let cfg = config.services.xserver.xss-lock;
in {
  options.services.xserver.xss-lock.enable = lib.mkEnableOption "xss-lock";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      xss-lock
      i3lock-color
    ];

    services.xserver.displayManager.sessionCommands = ''
      xss-lock i3lock-color &
    '';
  };
}
