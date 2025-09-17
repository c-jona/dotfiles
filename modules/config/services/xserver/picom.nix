{ config, lib, pkgs, ... }:
let cfg = config.services.xserver.picom;
in {
  options.services.xserver.picom.enable = lib.mkEnableOption "picom";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.picom ];

    home-files.allUsers.".config/picom.conf" = ''
      backend = "glx";
      rules = (
        { match = "window_type = 'normal'"; shadow = true; },
        { match = "window_type = 'dialog'"; shadow = true; },
        { match = "window_type = 'dock'"; shadow = true; },
        { match = "bounding_shaped"; shadow = false; },
        { match = "_NET_WM_STATE@[*] = '_NET_WM_STATE_HIDDEN'"; shadow = false; },
      );
      use-ewmh-active-win = true;
      vsync = true;
      xrender-sync-fence = true;
    '';

    services.xserver.displayManager.sessionCommands = ''
      picom &
    '';
  };
}
