{ config, lib, ... }:
let cfg = config.services.nh-clean;
in {
  options.services.nh-clean.enable = lib.mkEnableOption "nh-clean";

  config = lib.mkIf cfg.enable {
    programs.nh = {
      clean = {
        enable = true;
        dates = "daily";
        extraArgs = "--keep 3 --keep-since 7d";
      };
    };
  };
}
