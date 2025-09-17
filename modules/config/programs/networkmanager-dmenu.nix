{ config, lib, pkgs, ... }:
let cfg = config.programs.networkmanager-dmenu;
in {
  options.programs.networkmanager-dmenu.enable = lib.mkEnableOption "networkmanager-dmenu";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      networkmanagerapplet
      networkmanager_dmenu
    ];

    home-files.allUsers.".config/networkmanager-dmenu/config.ini" = lib.generators.toINI {} {
      editor.terminal = config.environment.variables.TERMINAL;
      dmenu = {
        dmenu_command = "rofi";
        pinentry = "pinentry";
        prompt = "network";
      };
      pinentry = {
        description = "Enter network password";
        prompt = "Password entry";
      };
    };
  };
}
