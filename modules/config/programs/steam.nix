{ pkgs, ... }:
{
  programs.steam.extraPackages = with pkgs; [
    adwaita-icon-theme
    adwaita-icon-theme-legacy
    mocu-xcursor
    morewaita-icon-theme
  ];
}
