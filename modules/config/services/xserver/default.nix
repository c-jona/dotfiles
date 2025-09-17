{ config, lib, pkgs, ... }:
let
  screenshot_script = select:
    pkgs.writeShellScriptBin "screenshot${if select then "-select" else ""}" ''
      ${if !select then ''
      (($# < 1)) && exit 1
      monitor="$1"
      '' else ""}
      screenshots_dir="$HOME/Pictures/Screenshots"
      file="$screenshots_dir/$(date +'%F_%T.%3N').png"
      ${if select then ''
      selection="$(slop -c 1,1,1,0.5 -kln 2>/dev/null)"
      [[ -z "$selection" ]] && exit 0
      '' else ""}
      mkdir -p "$screenshots_dir"
      if ffcast -q ${if select then "-g $selection" else "-x $(xrandr --listmonitors | grep \" $monitor$\" | cut -d ':' -f 1)"} png "$file" 2>/dev/null; then
        command -v notify-send >/dev/null && {
          response="$(notify-send --app-name screenshot --action 'default=Open File' Screenshot 'Screenshot saved & copied.'$'\n'''Click to open.')"
          [[ -n "$response" ]] && xdg-open "$file"
        } &
        xclip -selection clipboard -target image/png "$file"
        exit 0
      else
        command -v notify-send >/dev/null && notify-send --app-name screenshot Screenshot 'Screenshot failed.'
        exit 1
      fi
    '';

  screenshot = screenshot_script false;
  screenshot-select = screenshot_script true;

  cfg = config.services.xserver;
in lib.mkMerge [
  {
    services.xserver = {
      autoRepeatDelay = 350;
      autoRepeatInterval = 22;
      displayManager.sessionCommands = ''
        xset dpms 0 0 0
        xset -dpms
        xset s off
        xsetroot -cursor_name left_ptr
      '';
      xkb.options = "caps:escape";
    };
  }
  (lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      ffcast
      screenshot
      screenshot-select
      slop
      wmctrl
      xcolor
      xorg.xev
      xorg.xkill
      xclip
      xsel
    ];

    home-files.allUsers.".Xresources" = ''
      Xcursor.size: 24
      Xcursor.theme: Mocu-Iceberg-White-Right
    '';
  })
]
