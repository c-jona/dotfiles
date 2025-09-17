{ config, lib, ... }:
let cfg = config.programs.git;
in lib.mkMerge [
  {
    programs.git.config = {
      core.pager = "less -FX";
      init.defaultBranch = "main";
    };
  }
  (lib.mkIf cfg.enable {
    home-files.perUser.jona.".config/git/config" = ''
      [user]
      email=jonathancorynen@gmail.com
      name=Jona Corynen
    '';
  })
]
