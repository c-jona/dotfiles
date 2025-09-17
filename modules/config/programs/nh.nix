{ config, ... }:
{
  programs.nh.flake = config.users.users.jona.home + "/stuff/dotfiles";
}
