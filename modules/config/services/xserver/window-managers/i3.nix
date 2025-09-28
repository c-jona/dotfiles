{ config, lib, pkgs, ... }:
let
  spawn_bars = pkgs.writeShellScript "i3_spawn_bars" ''
    eww active-windows | grep -v '^bar_' | cut -d ':' -f 1 | xargs eww close >/dev/null 2>&1
    IFS=$'\n' read -d "" -r -a outputs < <(i3-msg -t get_outputs | jq -r 'map(select(.current_workspace!=null) | .name)[]')
    IFS=$'\n' read -d "" -r -a bars < <(eww active-windows | grep '^bar_' | cut -d ':' -f 1)
    for output in "''${outputs[@]}"; do
      if ! printf '%s\0' "''${bars[@]}" | grep -Fqxz "bar_$output"; then
        eww open bar --arg monitor="$output" --id "bar_$output" >/dev/null 2>&1
      fi
    done
    for bar in "''${bars[@]}"; do
      if ! printf '%s\0' "''${outputs[@]}" | grep -Fqxz "''${bar#bar_}"; then
        eww close "$bar" >/dev/null 2>&1
      fi
    done
  '';

  manage_outputs = pkgs.writeShellScript "i3_manage_outputs" ''
    $(eww get bar_hidden) || ${spawn_bars}
    i3-msg -t subscribe -m '["output"]' | while read _; do
      apply-wallpaper  # Fix wallpaper being broken sometimes
      $(eww get bar_hidden) || ${spawn_bars}
    done
  '';

  toggle_bar = pkgs.writeShellScript "i3_toggle_bar" ''
    if $(eww get bar_hidden); then
      ${spawn_bars}
      eww update bar_hidden=false
    else
      eww close-all
      eww update bar_hidden=true
    fi
  '';

  move_workspace_to_current_output = pkgs.writeShellScript "i3_move_workspace_to_current_output" ''
    (($# < 1)) && exit 1
    IFS=$'\n' read -d "" -r current_workspace current_output < <(i3-msg -t get_workspaces | jq -r '.[] | select(.focused) | [.name, .output][]')
    i3-msg --quiet "workspace --no-auto-back-and-forth $1; move workspace to output \"$current_output\""
    moving_workspace="$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).name')"
    i3-msg --quiet "workspace --no-auto-back-and-forth \"$current_workspace\"; workspace \"$moving_workspace\""
  '';

  move_next_prev = next:
    pkgs.writeShellScript "i3_move_${if next then "next" else "prev"}" ''
      layout=$(i3-msg -t get_tree | jq -r '.. | objects | select(has("nodes") and any(.nodes[]; .focused==true)).layout')
      case $layout in
        splith|tabbed) i3-msg --quiet 'move ${if next then "right" else "left"} 0 px' ;;
        splitv|stacked) i3-msg --quiet 'move ${if next then "down" else "up"} 0 px' ;;
      esac
    '';

  move_workspace_to_next_output = pkgs.writeShellScript "i3_move_workspace_to_next_output" ''
    i3-msg --quiet 'workspace back_and_forth'
    prev_workspace="$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).name')"
    i3-msg --quiet "workspace back_and_forth; move workspace to output next; workspace \"$prev_workspace\"; workspace back_and_forth"
  '';

  move_all_workspaces_to_next_output = pkgs.writeShellScript "i3_move_all_workspaces_to_next_output" ''
    declare -A "focused_workspaces=($(i3-msg -t get_outputs | jq -r '.[] | select(.current_workspace!=null) | "[" + .name + "]=\"" + .current_workspace + "\""'))"
    ((''${#focused_workspaces[@]} == 1)) && exit
    IFS=$'\n' read -d "" -r current_workspace current_output < <(i3-msg -t get_workspaces | jq -r '.[] | select(.focused) | [.name, .output][]')
    IFS=$'\n' read -d "" -r -a workspaces < <(i3-msg -t get_workspaces | jq -r 'map(.name)[]')
    for workspace in "''${workspaces[@]}"; do
      i3-msg --quiet "workspace --no-auto-back-and-forth \"$workspace\"; move workspace to output next"
    done
    for output in "''${!focused_workspaces[@]}"; do
      i3-msg --quiet "focus output \"$output\"; focus output next; workspace --no-auto-back-and-forth \"''${focused_workspaces["$output"]}\""
    done
    i3-msg --quiet "workspace --no-auto-back-and-forth \"$current_workspace\"; focus output \"$current_output\""
  '';

  cfg = config.services.xserver.windowManager.i3;
in lib.mkMerge [
  {
    services.xserver.windowManager.i3.extraPackages = lib.mkMerge [
      (with pkgs; [ alttab i3lock-color ])
      (lib.mkIf config.hardware.bluetooth.enable [ pkgs.bzmenu ])
    ];
  }
  (lib.mkIf cfg.enable {
    home-files.allUsers.".config/i3/config" = ''
      exec --no-startup-id "alttab -w 1 -d 0 -dk Delete -t 104x104 -i 104x48 -s 1 -bg '#0f1117' -fg '#c6c8d1' -frame '#242940' -inact '#1e2132' -font 'xft:MartianMono Nerd Font-10' -b 0 >/dev/null 2>&1"
      exec --no-startup-id "eww daemon >/dev/null 2>&1"
      exec --no-startup-id ${manage_outputs}
      exec --no-startup-id "i3-msg --quiet 'workspace 1'"

      client.background        #0f111700
      client.focused           #161821 #161821 #c6c8d1 #1e2132 #161821
      client.focused_inactive  #1e2132 #1e2132 #6b7089 #1e2132 #1e2132
      client.focused_tab_title #161821 #161821 #c6c8d1
      client.placeholder       #0f1117 #0f1117 #6b7089 #1e2132 #0f1117
      client.unfocused         #0f1117 #0f1117 #6b7089 #1e2132 #0f1117
      client.urgent            #e27878 #e27878 #161821 #1e2132 #e27878

      default_border normal 0
      default_floating_border normal 0

      default_orientation auto

      floating_modifier Mod4

      floating_minimum_size 40 x 40
      floating_maximum_size -1 x -1

      focus_follows_mouse no

      focus_on_window_activation smart

      focus_wrapping workspace

      font pango:monospace 16px

      force_display_urgency_hint 0 ms

      gaps inner 0 px
      gaps outer 0 px

      hide_edge_borders none

      mouse_warping none

      popup_during_fullscreen smart

      show_marks yes

      smart_gaps off

      tiling_drag modifier titlebar

      title_align left

      workspace_auto_back_and_forth yes

      workspace_layout tabbed

      for_window [all] title_window_icon padding 6 px
      for_window [tiling] border normal 0

      ${let
        bind = keysym: command: { inherit keysym command; };

        constant_keybinds = [
          (bind "button2" ''nop'')
          (bind "--release button2" ''kill'')
          (bind "button4" ''nop'')
          (bind "button5" ''nop'')

          (bind "XF86AudioMute" ''exec --no-startup-id "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"'')
          (bind "XF86AudioLowerVolume" ''exec --no-startup-id "wpctl set-volume --limit 1.0 @DEFAULT_AUDIO_SINK@ 5%-"'')
          (bind "XF86AudioRaiseVolume" ''exec --no-startup-id "wpctl set-volume --limit 1.0 @DEFAULT_AUDIO_SINK@ 5%+"'')

          (bind "Mod4+grave" ''exec --no-startup-id "monitor=\\"$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).output')\\"; toggle-menu powermenu \\"powermenu_$monitor\\" --arg monitor=\\"$monitor\\" --arg bar_hidden=$(eww get bar_hidden)"'')
        ];

        keybinds = rec {
          "default" = [
            (bind "Print" ''exec --no-startup-id "screenshot-select"'')
            (bind "Shift+Print" ''exec --no-startup-id "screenshot \\"$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).output')\\""'')

            (bind "Mod4+Shift+asciitilde" ''exec --no-startup-id "i3lock-color"'')

            (bind "Mod4+1" ''workspace 1'')
            (bind "Mod4+Shift+1" ''move container to workspace 1; workspace 1'')
            (bind "Mod4+Ctrl+1" ''exec --no-startup-id "${move_workspace_to_current_output} 1"'')
            (bind "Mod4+Ctrl+Shift+1" ''move container to workspace 1; exec --no-startup-id "${move_workspace_to_current_output} 1"'')

            (bind "Mod4+2" ''workspace 2'')
            (bind "Mod4+Shift+2" ''move container to workspace 2; workspace 2'')
            (bind "Mod4+Ctrl+2" ''exec --no-startup-id "${move_workspace_to_current_output} 2"'')
            (bind "Mod4+Ctrl+Shift+2" ''move container to workspace 2; exec --no-startup-id "${move_workspace_to_current_output} 2"'')

            (bind "Mod4+3" ''workspace 3'')
            (bind "Mod4+Shift+3" ''move container to workspace 3; workspace 3'')
            (bind "Mod4+Ctrl+3" ''exec --no-startup-id "${move_workspace_to_current_output} 3"'')
            (bind "Mod4+Ctrl+Shift+3" ''move container to workspace 3; exec --no-startup-id "${move_workspace_to_current_output} 3"'')

            (bind "Mod4+4" ''workspace 4'')
            (bind "Mod4+Shift+4" ''move container to workspace 4; workspace 4'')
            (bind "Mod4+Ctrl+4" ''exec --no-startup-id "${move_workspace_to_current_output} 4"'')
            (bind "Mod4+Ctrl+Shift+4" ''move container to workspace 4; exec --no-startup-id "${move_workspace_to_current_output} 4"'')

            (bind "Mod4+5" ''workspace 5'')
            (bind "Mod4+Shift+5" ''move container to workspace 5; workspace 5'')
            (bind "Mod4+Ctrl+5" ''exec --no-startup-id "${move_workspace_to_current_output} 5"'')
            (bind "Mod4+Ctrl+Shift+5" ''move container to workspace 5; exec --no-startup-id "${move_workspace_to_current_output} 5"'')

            (bind "Mod4+6" ''workspace 6'')
            (bind "Mod4+Shift+6" ''move container to workspace 6; workspace 6'')
            (bind "Mod4+Ctrl+6" ''exec --no-startup-id "${move_workspace_to_current_output} 6"'')
            (bind "Mod4+Ctrl+Shift+6" ''move container to workspace 6; exec --no-startup-id "${move_workspace_to_current_output} 6"'')

            (bind "Mod4+7" ''workspace 7'')
            (bind "Mod4+Shift+7" ''move container to workspace 7; workspace 7'')
            (bind "Mod4+Ctrl+7" ''exec --no-startup-id "${move_workspace_to_current_output} 7"'')
            (bind "Mod4+Ctrl+Shift+7" ''move container to workspace 7; exec --no-startup-id "${move_workspace_to_current_output} 7"'')

            (bind "Mod4+8" ''workspace 8'')
            (bind "Mod4+Shift+8" ''move container to workspace 8; workspace 8'')
            (bind "Mod4+Ctrl+8" ''exec --no-startup-id "${move_workspace_to_current_output} 8"'')
            (bind "Mod4+Ctrl+Shift+8" ''move container to workspace 8; exec --no-startup-id "${move_workspace_to_current_output} 8"'')

            (bind "Mod4+9" ''workspace 9'')
            (bind "Mod4+Shift+9" ''move container to workspace 9; workspace 9'')
            (bind "Mod4+Ctrl+9" ''exec --no-startup-id "${move_workspace_to_current_output} 9"'')
            (bind "Mod4+Ctrl+Shift+9" ''move container to workspace 9; exec --no-startup-id "${move_workspace_to_current_output} 9"'')

            (bind "Mod4+0" ''workspace 10'')
            (bind "Mod4+Shift+0" ''move container to workspace 10; workspace 10'')
            (bind "Mod4+Ctrl+0" ''exec --no-startup-id "${move_workspace_to_current_output} 10"'')
            (bind "Mod4+Ctrl+Shift+0" ''move container to workspace 10; exec --no-startup-id "${move_workspace_to_current_output} 10"'')

            (bind "Mod4+Tab" ''workspace back_and_forth'')
            (bind "Mod4+Shift+Tab" ''move container to workspace back_and_forth; workspace back_and_forth'')
            (bind "Mod4+Ctrl+Tab" ''exec --no-startup-id "${move_workspace_to_current_output} back_and_forth"'')
            (bind "Mod4+Ctrl+Shift+Tab" ''move container to workspace back_and_forth; exec --no-startup-id "${move_workspace_to_current_output} back_and_forth"'')

            (bind "Mod4+minus" ''fullscreen toggle'')
            (bind "Mod4+Shift+underscore" ''exec --no-startup-id ${toggle_bar}'')

            (bind "Mod4+q" ''kill'')
            (bind "Mod4+Shift+q" ''[workspace=__focused__] kill'')

            (bind "Mod4+w" ''focus prev'')
            (bind "Mod4+Shift+w" ''exec --no-startup-id ${move_next_prev false}'')

            (bind "Mod4+e" ''focus next'')
            (bind "Mod4+Shift+e" ''exec --no-startup-id ${move_next_prev true}'')

            (bind "Mod4+r" ''exec --no-startup-id "rofi -show-icons -show drun"'')
            (bind "Mod4+Shift+r" ''reload'')

            (bind "Mod4+t" ''focus mode_toggle'')
            (bind "Mod4+Shift+t" ''floating toggle'')

            (bind "Mod4+y" ''layout toggle tabbed split'')
            (bind "Mod4+Shift+y" ''layout toggle split'')

            (bind "Mod4+u" ''focus parent'')
            (bind "Mod4+Shift+u" ''split vertical'')

            (bind "Mod4+i" ''focus child'')
            (bind "Mod4+Shift+i" ''split horizontal'')

            (bind "Mod4+o" ''workspace prev_on_output'')
            (bind "Mod4+Shift+o" ''move container to workspace prev_on_output; workspace prev_on_output'')

            (bind "Mod4+p" ''workspace next_on_output'')
            (bind "Mod4+Shift+p" ''move container to workspace next_on_output; workspace next_on_output'')

            (bind "Mod4+h" ''focus left'')
            (bind "Mod4+Shift+h" ''move left 40 px'')
            (bind "Mod4+Ctrl+h" ''resize shrink width 40 px'')

            (bind "Mod4+j" ''focus down'')
            (bind "Mod4+Shift+j" ''move down 40 px'')
            (bind "Mod4+Ctrl+j" ''resize grow height 40 px'')

            (bind "Mod4+k" ''focus up'')
            (bind "Mod4+Shift+k" ''move up 40 px'')
            (bind "Mod4+Ctrl+k" ''resize shrink height 40 px'')

            (bind "Mod4+l" ''focus right'')
            (bind "Mod4+Shift+l" ''move right 40 px'')
            (bind "Mod4+Ctrl+l" ''resize grow width 40 px'')

            (bind "Mod4+semicolon" ''focus output next'')
            (bind "Mod4+Shift+colon" ''move container to output next; focus output next'')
            (bind "Mod4+Ctrl+semicolon" ''exec --no-startup-id ${move_workspace_to_next_output}'')
            (bind "Mod4+Ctrl+Shift+colon" ''exec --no-startup-id ${move_all_workspaces_to_next_output}'')

            (bind "Mod4+Return" ''exec --no-startup-id "$TERMINAL"'')

            (bind "Mod4+c" ''exec --no-startup-id "clipmenu -p clipboard"'')
            (bind "Mod4+Shift+c" ''exec --no-startup-id "xcolor --selection"'')

            (bind "Mod4+n" ''exec --no-startup-id networkmanager_dmenu'')

            (bind "Mod4+space" ''exec --no-startup-id "rofi -show-icons -show window"'')

            (bind "Mod4+Left" ''focus left'')
            (bind "Mod4+Shift+Left" ''move left 40 px'')
            (bind "Mod4+Ctrl+Left" ''resize shrink width 40 px'')

            (bind "Mod4+Down" ''focus down'')
            (bind "Mod4+Shift+Down" ''move down 40 px'')
            (bind "Mod4+Ctrl+Down" ''resize grow height 40 px'')

            (bind "Mod4+Up" ''focus up'')
            (bind "Mod4+Shift+Up" ''move up 40 px'')
            (bind "Mod4+Ctrl+Up" ''resize shrink height 40 px'')

            (bind "Mod4+Right" ''focus right'')
            (bind "Mod4+Shift+Right" ''move right 40 px'')
            (bind "Mod4+Ctrl+Right" ''resize grow width 40 px'')
          ] ++ (
            if config.hardware.bluetooth.enable
            then [
              (bind "Mod4+b" ''exec --no-startup-id "bzmenu --icon font --launcher custom --launcher-command 'rofi -dmenu -p bluetooth'"'')
            ]
            else []
          );

          "_menu_active" = [
            (bind "Escape" ''exec --no-startup-id "close-active-menus"'')
          ] ++ map ({ keysym, command }:
            (bind keysym ''exec --no-startup-id "close-active-menus"; ${command}'')
          ) default;
        };
      in builtins.concatStringsSep "\n" (
        map ({ name, value }:
          ''
            ${if name != "default" then "mode \"${name}\" {" else ""}
            ${
              builtins.concatStringsSep "\n" (
                map ({ keysym, command }:
                  "bindsym ${keysym} ${command}"
                ) (constant_keybinds ++ value)
              )
            }
            ${if name != "default" then "}" else ""}
          ''
        ) (lib.attrsToList keybinds)
      )}
    '';

    programs = {
      eww.enable = true;
      networkmanager-dmenu.enable = true;
    };
  })
]
