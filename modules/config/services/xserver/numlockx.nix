{ config, lib, pkgs, ... }:
let cfg = config.services.xserver.numlockx;
in {
  options.services.xserver.numlockx.enable = lib.mkEnableOption "numlockx";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.numlockx ];

    services.xserver.displayManager.sessionCommands = ''
      numlockx
    '';
  };
}
