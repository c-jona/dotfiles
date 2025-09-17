{
  programs.direnv = {
    direnvrcExtra = ''
      export DIRENV_ACTIVE=1
    '';
    nix-direnv.enable = true;
    settings.global.log_filter = "^loading ";
  };
}
