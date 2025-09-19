{ config, lib, pkgs, ... }:
let cfg = config.services.xserver.clipmenu;
in {
  options.services.xserver.clipmenu.enable = lib.mkEnableOption "clipmenu";

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = [ pkgs.clipmenu ];
      variables = {
        CM_HISTLENGTH = 10;
        CM_LAUNCHER = "rofi";
        CM_SELECTIONS = "clipboard";
      };
    };

    services.xserver.displayManager.sessionCommands = ''
      clipmenud &
    '';
  };
}
