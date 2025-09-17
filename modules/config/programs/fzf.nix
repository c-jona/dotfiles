{ config, lib, ... }:
let cfg = config.programs.fzf;
in {
  options.programs.fzf.enable = lib.mkEnableOption "fzf";

  config = lib.mkIf cfg.enable {
    environment.variables = {
      FZF_ALT_C_OPTS = "--height=~12";
      FZF_COMPLETION_OPTS = "--height=~12";
      FZF_DEFAULT_OPTS = "--border=none --color=fg:#c6c8d1,fg+:#c6c8d1,bg:#161821,bg+:#1e2132,hl:#b4be82,hl+:#b4be82,info:#a093c7,marker:#89b8c2,prompt:#e27878,spinner:#6b7089,pointer:#c6c8d1,header:#84a0c6,gutter:#161821,border:#6b7089,label:#c6c8d1,query:#c6c8d1 --cycle --layout=reverse --preview-border=sharp --scroll-off=3";
      FZF_CTRL_R_OPTS = "--height=~12";
      FZF_CTRL_T_OPTS = "--height=~12";
    };

    programs.fzf = {
      keybindings = true;
      fuzzyCompletion = true;
    };
  };
}
