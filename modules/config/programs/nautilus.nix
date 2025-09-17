{ config, lib, pkgs, ... }:
let cfg = config.programs.nautilus;
in {
  options.programs.nautilus.enable = lib.mkEnableOption "nautilus";

  config = lib.mkIf cfg.enable {
    environment = {
      pathsToLink = [ "/share/nautilus-python/extensions" ];
      sessionVariables.NAUTILUS_4_EXTENSION_DIR = "${pkgs.nautilus-python}/lib/nautilus/extensions-4";
      systemPackages = with pkgs; [
        nautilus
        nautilus-open-any-terminal
        nautilus-python
      ];
    };

    programs.dconf.profiles.user.databases = [
      {
        lockAll = true;
        settings."com/github/stunkymonkey/nautilus-open-any-terminal".terminal = config.environment.variables.TERMINAL;
      }
    ];
  };
}
