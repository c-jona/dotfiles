{ config, lib, pkgs, ... }:
let
  apply-wallpaper = pkgs.writeShellScriptBin "apply-wallpaper" ''
    ${pkgs.feh}/bin/feh --bg-${cfg.mode} --no-fehbg ${cfg.source}
  '';

  cfg = config.services.xserver.wallpaper;
in {
  options.services.xserver.wallpaper = {
    enable = lib.mkEnableOption "xorg wallpaper";
    mode = lib.mkOption {
      default = "scale";
      description = "feh wallpaper mode";
      type = lib.types.enum [
        "center"
        "fill"
        "max"
        "scale"
        "tile"
      ];
    };
    source = lib.mkOption {
      description = "wallpaper source";
      type = lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ apply-wallpaper ];

    services.xserver.displayManager.sessionCommands = ''
      apply-wallpaper
    '';
  };
}
