{ config, lib, pkgs, ... }:
let
  open_menu_closers = pkgs.writeShellScript "eww_open_menu_closers" ''
    IFS=$'\n' read -d "" -r -a outputs < <(i3-msg -t get_outputs | jq -r 'map(select(.current_workspace!=null) | .name)[]')
    for output in "''${outputs[@]}"; do
      id="menu_closer_$output"
      if ! eww active-windows | grep -q "^$id:"; then
        eww open menu_closer --arg monitor="$output" --arg bar_hidden=$(eww get bar_hidden) --id "$id" >/dev/null 2>&1
      fi
    done
    i3-msg --quiet "mode _menu_active"
  '';

  close_menu_closers = pkgs.writeShellScript "eww_close_menu_closers" ''
    [[ -n "$(eww get active_menus)" ]] && exit 1
    IFS=$'\n' read -d "" -r -a menu_closers < <(eww active-windows | grep '^menu_closer_' | cut -d ':' -f 1)
    for menu_closer in "''${menu_closers[@]}"; do
      eww close "$menu_closer" >/dev/null 2>&1
    done
    i3-msg --quiet "mode default"
  '';

  open-menu = pkgs.writeShellScriptBin "open-menu" ''
    (($# < 2)) && exit 1
    window="$1"; id="$2"
    shift 2
    ${open_menu_closers}
    eww open "$window" --id "$id" "$@" >/dev/null 2>&1
    active_menus="$(eww get active_menus)"$'\n'"$id"
    eww update active_menus="''${active_menus#$'\n'}"
  '';

  close-menu = pkgs.writeShellScriptBin "close-menu" ''
    (($# < 1)) && exit 1
    eww close "$1" >/dev/null 2>&1
    eww update active_menus="$(eww get active_menus | grep -vx "$1")"
    ${close_menu_closers}
  '';

  toggle-menu = pkgs.writeShellScriptBin "toggle-menu" ''
    (($# < 2)) && exit 1
    if eww active-windows | grep -q "^$2:"; then
      close-menu "$2"
    else
      open-menu "$@"
    fi
  '';

  close-active-menus = pkgs.writeShellScriptBin "close-active-menus" ''
    IFS=$'\n' read -d "" -r -a active_menus < <(eww get active_menus)
    for id in "''${active_menus[@]}"; do
      eww close "$id" >/dev/null 2>&1
    done
    eww update active_menus=""
    ${close_menu_closers}
  '';

  poll_notifications = pkgs.writeShellScript "eww_poll_notifications" ''
    paused="$(dunstctl is-paused)"
    remaining="$(dunstctl count waiting)"
    echo "{\"paused\": ''${paused},\"remaining\": ''${remaining}}"
  '';

  poll_network = pkgs.writeShellScript "eww_poll_network" ''
    nmcli --terse device status | {
      while IFS=':' read -r DEVICE TYPE STATE CONNECTION; do
        if [[ "$TYPE" == 'ethernet' ]]; then
          ethernet_state="$STATE"
          ethernet_connection="$CONNECTION"
        fi
        if [[ "$TYPE" == 'wifi' ]]; then
          wifi_state="$STATE"
          wifi_connection="$CONNECTION"
        fi
      done
      echo "{\"ethernet\": {\"state\": \"''${ethernet_state^}\",\"connection\": \"$ethernet_connection\"},\"wifi\": {\"state\": \"''${wifi_state^}\",\"connection\": \"$wifi_connection\"}}"
    }
  '';

  poll_bluetooth = pkgs.writeShellScript "eww_poll_bluetooth" ''
    default_controller="$(bluetoothctl list | grep '\[default\]' | awk '{print $2}')"
    power_state="$(bluetoothctl show "$default_controller" | grep 'PowerState:' | awk '{print $2}')"
    echo "{\"power_state\": \"''${power_state^}\"}"
  '';

  listen_workspaces = pkgs.writeShellScript "eww_listen_workspaces" ''
    i3-msg -t get_workspaces
    i3-msg -t subscribe -m '["output", "workspace"]' | while read _; do
      i3-msg -t get_workspaces
    done
  '';

  listen_microphone = pkgs.writeShellScript "eww_listen_microphone" ''
    set_default_source() {
      default_source="$(pactl get-default-source)"
      default_source_index=$(pactl --format=json list sources short | jq ".[] | select(.name==\"$default_source\").index")
    }

    get_status() {
      pactl --format=json list sources | jq -c ".[] | select(.index==$default_source_index) | {\"source\": .name, \"description\": .description, \"muted\": .mute, \"level\": .volume[].value_percent | rtrimstr(\"%\") | tonumber}"
    }

    sleep 1
    default_source_index=""
    while [[ -z "$default_source_index" ]]; do
      set_default_source
      sleep 0.05
    done

    get_status
    pactl --format=json subscribe | while read -r EVENT; do
      if $(jq ".event==\"change\" and (.on==\"server\" or (.on==\"source\" and .index==$default_source_index))" <<< "$EVENT"); then
        if $(jq '.on=="server"' <<< "$EVENT"); then
          set_default_source
        fi
        get_status
      fi
    done
  '';

  listen_volume = pkgs.writeShellScript "eww_listen_volume" ''
    set_default_sink() {
      default_sink="$(pactl get-default-sink)"
      default_sink_index=$(pactl --format=json list sinks short | jq ".[] | select(.name==\"$default_sink\").index")
    }

    get_status() {
      pactl --format=json list sinks | jq -c ".[] | select(.index==$default_sink_index) | {\"sink\": .name, \"description\": .description, \"muted\": .mute, \"level\": .volume[].value_percent | rtrimstr(\"%\") | tonumber}"
    }

    sleep 1
    default_sink_index=""
    while [[ -z "$default_sink_index" ]]; do
      set_default_sink
      sleep 0.05
    done

    get_status
    pactl --format=json subscribe | while read -r EVENT; do
      if $(jq ".event==\"change\" and (.on==\"server\" or (.on==\"sink\" and .index==$default_sink_index))" <<< "$EVENT"); then
        if $(jq '.on=="server"' <<< "$EVENT"); then
          set_default_sink
        fi
        get_status
      fi
    done
  '';

  listen_brightness = pkgs.writeShellScript "eww_listen_brightness" ''
    get-brightness
    inotifywait --event MODIFY --monitor --quiet /sys/class/backlight/$(get-brightness-device)/brightness | while read _; do
      get-brightness
    done
  '';

  cfg = config.programs.eww;
in {
  options.programs.eww.enable = lib.mkEnableOption "eww";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = lib.mkMerge [
      [ pkgs.eww open-menu close-menu toggle-menu close-active-menus ]
      (lib.mkIf config.hardware.bluetooth.enable [ pkgs.bzmenu ])
    ];

    home-files.allUsers.".config/eww" = {
      "eww.scss" = ''
        * {
          all: unset;
        }

        window {
          color: #c6c8d1;
          font-family: "monospace";
          font-size: 16px;
          font-weight: 500;
        }

        window.calendar {
          background-color: #0f1117;
          border-radius: 15px 0px 0px 0px;
        }

        box.calendar {
          padding: 12px 12px 0px 12px;

          calendar {
            padding: 0px 3px 3px 3px;

            &:indeterminate {
              color: #6b7089;
            }

            &:selected {
              background-color: #2a3158;
              border-radius: 8px;
              color: #d2d4de;
            }

            &.button:hover {
              background-color: #1e2132;
              border-radius: 4px;
            }
          }
        }

        window.powermenu, window.powermenu_confirm {
          background-color: #0f1117;
          border-radius: 0px 15px 0px 0px;
        }

        box.powermenu, box.powermenu_confirm {
          padding: 12px 12px 6px 12px;

          .icon {
            font-size: 18px;
          }

          .icon_text {
            border-radius: 10px;
            padding: 3px 6px;

            .icon {
              margin-right: 6px;
            }
          }

          .prompt {
            margin-bottom: 3px;
          }

          button {
            border: 1px solid rgba(0, 0, 0, 0%);

            &:focus {
              border: 1px solid rgba(198, 200, 209, 75%);
              background-color: #161821;
            }

            &:hover {
              background-color: #1e2132;
            }
          }
        }

        window.bar {
          background-color: #161821;
        }

        box.bar {
          .icon {
            font-size: 18px;
          }

          .icon_text .icon {
            margin-right: 6px;
          }

          .icon_scale {
            .icon {
              margin-right: 12px;
            }

            scale trough {
              background-color: #07080a;
              border-radius: 5px;
              min-width: 100px;
              min-height: 12px;

              highlight {
                background-color: #6b7089;
                border-radius: 5px;

                &:hover {
                  background-color: #c6c8d1;
                }
              }
            }
          }

          .left {
            background-color: #0f1117;
            border-radius: 0px 10px 10px 0px;
            color: #6b7089;
            padding: 0px 24px 0px 18px;
          }

          .center {
            background-color: #0f1117;
            border-radius: 10px;
            color: #6b7089;
            padding-left: 24px;
          }

          .workspaces .icon {
            margin-right: 18px;
          }

          .workspace {
            border-radius: 10px;
            padding: 0px 12px;
            min-width: 24px;

            &.urgent {
              background-color: #e27878;
              color: #161821;

              &:not(.focused):not(.visible):hover {
                background-color: #e98989;
              }
            }

            &.visible {
              background-color: #242940;
              color: #6b7089;

              &:not(.focused):hover {
                color: #c6c8d1;
              }
            }

            &.focused {
              background-color: #c6c8d1;
              color: #161821;
            }
          }

          .right {
            background-color: #0f1117;
            border-radius: 10px 0px 0px 10px;
            color: #6b7089;
            padding-right: 18px;
          }

          .tray {
            image {
              opacity: 0.5;
            }

            widget {
              &:hover image {
                opacity: 1;
              }

              &:first-child image {
                padding-left: 24px;
              }
            }

            window {
              background-color: #0f1117;
            }

            menu {
              padding: 6px;

              separator {
                background-color: #1e2132;
                margin: 3px 0px;
                min-height: 1px;
              }

              > menuitem {
                border-radius: 10px;
                font-size: 16px;
                padding: 3px 6px;

                &:hover {
                  background-color: #1e2132;
                }

                &:disabled label {
                  color: #6b7089;
                }
              }
            }
          }

          button:hover {
            color: #c6c8d1;
          }
        }

        tooltip {
          background-color: #0f1117;
          color: #c6c8d1;
          font-family: "monospace";
          font-size: 16px;
          font-weight: 500;
        }
      '';
      "eww.yuck" = ''
        (defvar active_menus "")

        (defvar bar_hidden false)

        (defpoll time :initial '{"year": "1970","month": "01","month_abbr": "Jan","month_full": "January","day": "01","day_of_year": "001","day_of_week": "4","day_of_week_abbr": "Thu", "day_of_week_full": "Thursday","hour": "01","minute": "00","second": "00"}'
                      :interval "1s"
          "date +'{\"year\": \"%Y\",\"month\": \"%m\",\"month_abbr\": \"%b\",\"month_full\": \"%B\",\"day\": \"%d\",\"day_of_year\": \"%j\",\"day_of_week\": \"%u\",\"day_of_week_abbr\": \"%a\", \"day_of_week_full\": \"%A\",\"hour\": \"%H\",\"minute\": \"%M\",\"second\": \"%S\"}'")

        (defpoll notifications :initial '{"paused": false,"remaining": 0}'
                               :interval "1s"
          "${poll_notifications}")

        (defpoll network :initial '{"ethernet": {"state": "","connection": ""},"wifi": {"state": "","connection": ""}}'
                         :interval "1s"
          "${poll_network}")

        ${if config.hardware.bluetooth.enable then ''
        (defpoll bluetooth :initial '{"power_state": "Off"}'
                           :interval "1s"
          "${poll_bluetooth}")
        '' else ""}

        (deflisten workspaces :initial "[]"
          "${listen_workspaces}")

        (deflisten microphone :initial '{"source":"auto_null"}'
          "${listen_microphone}")

        (deflisten volume :initial '{"sink":"auto_null"}'
          "${listen_volume}")

        ${if config.hardware.brightness-controls.enable then ''
        (deflisten brightness :initial 0
          "${listen_brightness}")
        '' else ""}

        (defwidget icon [icon ?active ?onclick ?onmiddleclick ?onrightclick ?tooltip]
          (button :active {active ?: true}
                  :timeout "1s"
                  :onclick onclick
                  :onmiddleclick onmiddleclick
                  :onrightclick onrightclick
                  :tooltip tooltip
            (label :text icon
                   :class "icon")))

        (defwidget icon_text [icon text ?active ?onclick ?onmiddleclick ?onrightclick ?tooltip]
          (button :active {active ?: true}
                  :timeout "1s"
                  :onclick onclick
                  :onmiddleclick onmiddleclick
                  :onrightclick onrightclick
                  :tooltip tooltip
                  :class "icon_text"
            (box :space-evenly false
              (label :text icon
                     :class "icon")
              (label :text text
                     :class "text"))))

        (defwidget icon_scale [icon value ?active ?onclick ?onmiddleclick ?onrightclick ?onchange ?tooltip]
          (box :space-evenly false
               :tooltip tooltip
               :class "icon_scale"
            (button :active {active ?: true}
                    :timeout "1s"
                    :onclick onclick
                    :onmiddleclick onmiddleclick
                    :onrightclick onrightclick
              (label :text icon
                     :class "icon"))
            (scale :active {active ?: true}
                   :timeout "1s"
                   :max 101
                   :min 0
                   :onchange onchange
                   :value value)))

        (defwidget time [calendar_monitor]
          (button :active true
                  :timeout "1s"
                  :onclick "toggle-menu calendar \"calendar_''${calendar_monitor}\" --arg monitor=\"''${calendar_monitor}\" --arg bar_hidden=$(eww get bar_hidden)"
                  :tooltip "''${time.day_of_week_full}, ''${time.day} ''${time.month_full} ''${time.year}"
                  :class "time"
            (label :text "''${time.hour}:''${time.minute}"
                   :class "text")))

        (defwidget _battery [battery]
          (icon_text :icon {battery.status == "Charging" ? (battery.capacity == 100 ? "󰂅" :
                                                            battery.capacity >= 90 ? "󰂋" :
                                                            battery.capacity >= 80 ? "󰂊" :
                                                            battery.capacity >= 70 ? "󰢞" :
                                                            battery.capacity >= 60 ? "󰂉" :
                                                            battery.capacity >= 50 ? "󰢝" :
                                                            battery.capacity >= 40 ? "󰂈" :
                                                            battery.capacity >= 30 ? "󰂇" :
                                                            battery.capacity >= 20 ? "󰂆" :
                                                            battery.capacity >= 10 ? "󰢜" :
                                                            "󰢟") :
                            battery.capacity == 100 ? "󰁹" :
                            battery.capacity >= 90 ? "󰂂" :
                            battery.capacity >= 80 ? "󰂁" :
                            battery.capacity >= 70 ? "󰂀" :
                            battery.capacity >= 60 ? "󰁿" :
                            battery.capacity >= 50 ? "󰁾" :
                            battery.capacity >= 40 ? "󰁽" :
                            battery.capacity >= 30 ? "󰁼" :
                            battery.capacity >= 20 ? "󰁻" :
                            battery.capacity >= 10 ? "󰁺" :
                            "󰂎"}
                       :text "''${battery.capacity}%"
                       :tooltip "Battery: ''${battery.status}"))

        (defwidget battery []
          (box :class "battery"
            (_battery :battery {jq(EWW_BATTERY, 'to_entries | map(select(.key | match("^BAT"))) | first.value')})))

        (defwidget memory []
          (box :class "memory"
            (icon_text :icon "󰍛"
                         :text "''${round(EWW_RAM.used_mem_perc, 1)}%"
                         :tooltip "Memory: Using ''${formatbytes(round(EWW_RAM.used_mem, 0), true)}/''${formatbytes(round(EWW_RAM.total_mem, 0), true)}")))

        (defwidget notifications []
          (box :class "notifications"
            (icon :icon {notifications.paused ? "󰂛" : "󰂚"}
                  :onclick "dunstctl set-paused toggle; eww poll notifications"
                  :tooltip "Notifications: ''${notifications.remaining} remaining''${notifications.paused ? " (paused)" : ""}")))

        (defwidget ethernet []
          (box :visible {network.ethernet.state != ""}
               :class "ethernet"
            (icon :icon {network.ethernet.state == "Connected" ? "󰈁" : "󰈂"}
                  :onclick "close-active-menus; networkmanager_dmenu -m -5 &"
                  :tooltip "Ethernet: ''${network.ethernet.state == "Connected" ? "Connected to ''${network.ethernet.connection}" : network.ethernet.state}")))

        (defwidget wifi []
          (box :visible {network.wifi.state != ""}
               :class "wifi"
            (icon :icon {network.wifi.state == "Connected" ? "󰖩" : "󰖪"}
                  :onclick "close-active-menus; networkmanager_dmenu -m -5 &"
                  :tooltip "Wifi: ''${network.wifi.state == "Connected" ? "Connected to ''${network.wifi.connection}" : network.wifi.state}")))

        ${if config.hardware.bluetooth.enable then ''
        (defwidget bluetooth []
          (box :class "bluetooth"
            (icon :icon {bluetooth.power_state == "On" ? "󰂯" : "󰂲"}
                  :onclick "close-active-menus; bzmenu --icon font --launcher custom --launcher-command 'rofi -dmenu -m -5 -p bluetooth' &"
                  :tooltip "Bluetooth: ''${bluetooth.power_state}")))
        '' else ""}

        (defwidget tray []
          (box :class "tray"
            (systray :icon-size 20
                     :prepend-new true
                     :space-evenly false
                     :spacing 12)))

        (defwidget workspaces [monitor]
          (box :space-evenly false
               :spacing 6
               :class "workspaces"
            (icon :icon "󰄶"
                  :onclick "close-active-menus; rofi -m -5 -show-icons -show window &"
                  :onrightclick "close-active-menus; rofi -m -5 -show-icons -show drun &")
            (for workspace in {jq(workspaces, 'map(select(.output=="''${monitor}"))')}
              (button :active true
                      :timeout "1s"
                      :onclick 'i3-msg --quiet \'workspace --no-auto-back-and-forth "''${workspace.name}"\'''
                      :class "workspace''${workspace.focused ? " focused" : ""}''${workspace.urgent ? " urgent" : ""}''${workspace.visible ? " visible" : ""}"
                (label :text {workspace.name}
                       :class "text")))))

        (defwidget microphone []
          (box :class "microphone"
            (icon_scale :icon {microphone.source == "auto_null" ? "󰍭" :
                               microphone.muted ? "󰍮" :
                               "󰍬"}
                          :value {microphone.source == "auto_null" ? 0 : microphone.level}
                          :onclick {microphone.source == "auto_null" ? "" : "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"}
                          :onchange {microphone.source == "auto_null" ? "" : "wpctl set-volume @DEFAULT_AUDIO_SOURCE@ {}%"}
                          :tooltip "Microphone: ''${microphone.source == "auto_null" ? "No input" : "''${microphone.level}%''${microphone.muted ? " (muted)" : ""}"}")))

        (defwidget volume []
          (box :class "volume"
            (icon_scale :icon {volume.sink == "auto_null" ? "󰸈" :
                               volume.muted ? "󰝟" :
                               volume.level >= 70 ? "󰕾" :
                               volume.level >= 35 ? "󰖀" :
                               "󰕿"}
                          :value {volume.sink == "auto_null" ? 0 : volume.level}
                          :onclick {volume.sink == "auto_null" ? "" : "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"}
                          :onchange {volume.sink == "auto_null" ? "" : "wpctl set-volume @DEFAULT_AUDIO_SINK@ {}%"}
                          :tooltip "Volume: ''${volume.sink == "auto_null" ? "No output" : "''${volume.level}%''${volume.muted ? " (muted)" : ""}"}")))

        ${if config.hardware.brightness-controls.enable then ''
        (defwidget brightness []
          (box :class "brightness"
            (icon_scale :icon "󰃟"
                          :value brightness
                          :onchange "set-brightness {}"
                          :tooltip "Brightness: ''${brightness}%")))
        '' else ""}

        (defwidget power [powermenu_monitor]
          (box :class "power"
            (icon :icon "󰐥"
                  :onclick "toggle-menu powermenu \"powermenu_''${powermenu_monitor}\" --arg monitor=\"''${powermenu_monitor}\" --arg bar_hidden=$(eww get bar_hidden)")))

        (defwindow menu_closer [monitor ?bar_hidden]
                   :geometry (geometry :anchor "bottom center"
                                       :height "100%"
                                       :width "100%"
                                       :x "0px"
                                       :y {(bar_hidden ?: false) ? "0px" : "-24px"})
                   :monitor monitor
                   :stacking "fg"
                   :windowtype "desktop"
          (eventbox :active true
                    :timeout "1s"
                    :onclick "close-active-menus"))

        (defwindow calendar [monitor ?bar_hidden]
                   :geometry (geometry :anchor "bottom right"
                                       :x "0px"
                                       :y {(bar_hidden ?: false) ? "0px" : "-24px"})
                   :monitor monitor
                   :stacking "fg"
                   :windowtype "desktop"
          (box :halign "center"
               :valign "center"
            (calendar :show-day-names false
                      :show-details true
                      :show-heading true
                      :show-week-numbers false)))

        (defwindow powermenu [monitor ?bar_hidden]
                   :geometry (geometry :anchor "bottom left"
                                       :x "0px"
                                       :y {(bar_hidden ?: false) ? "0px" : "-24px"})
                   :monitor monitor
                   :stacking "fg"
                   :windowtype "desktop"
          (box :orientation "vertical"
               :space-evenly false
               :halign "center"
               :valign "center"
            (icon_text :icon "󰐥"
                       :text "Shut down"
                       :onclick "open-menu powermenu_confirm \"powermenu_''${monitor}\" --arg monitor=\"''${monitor}\" --arg bar_hidden=$(eww get bar_hidden) --arg icon=\"󰐥\" --arg text=\"Shut down?\" --arg command=\"systemctl poweroff\"")
            (icon_text :icon "󰜉"
                       :text "Restart"
                       :onclick "open-menu powermenu_confirm \"powermenu_''${monitor}\" --arg monitor=\"''${monitor}\" --arg bar_hidden=$(eww get bar_hidden) --arg icon=\"󰜉\" --arg text=\"Restart?\" --arg command=\"systemctl reboot\"")
            (icon_text :icon "󰤄"
                       :text "Sleep"
                       :onclick "open-menu powermenu_confirm \"powermenu_''${monitor}\" --arg monitor=\"''${monitor}\" --arg bar_hidden=$(eww get bar_hidden) --arg icon=\"󰤄\" --arg text=\"Sleep?\" --arg command=\"systemctl suspend\"")
            (icon_text :icon "󰍃"
                       :text "Sign out"
                       :onclick "open-menu powermenu_confirm \"powermenu_''${monitor}\" --arg monitor=\"''${monitor}\" --arg bar_hidden=$(eww get bar_hidden) --arg icon=\"󰍃\" --arg text=\"Sign out?\" --arg command=\"pkill -x X\"")))

        (defwindow powermenu_confirm [monitor ?bar_hidden icon text command]
                   :geometry (geometry :anchor "bottom left"
                                       :x "0px"
                                       :y {(bar_hidden ?: false) ? "0px" : "-24px"})
                   :monitor monitor
                   :stacking "fg"
                   :windowtype "desktop"
          (box :orientation "vertical"
               :space-evenly false
               :halign "center"
               :valign "center"
            (box :halign "start"
                 :class "prompt"
              (icon_text :icon icon
                         :text text
                         :active false))
            (box :orientation "horizontal"
                 :space-evenly true
                 :halign "fill"
              (icon_text :icon "󰄬"
                         :text "Yes"
                         :onclick "close-menu \"powermenu_''${monitor}\"; ''${command}")
              (icon_text :icon "󰅖"
                         :text "No"
                         :onclick "close-menu \"powermenu_''${monitor}\""))))

        (defwindow bar [monitor]
                   :geometry (geometry :anchor "bottom center"
                                       :height "24px"
                                       :width "100%"
                                       :x "0px"
                                       :y "0px")
                   :monitor monitor
                   :stacking "fg"
                   :windowtype "dock"
          (centerbox :orientation "horizontal"
            (box :space-evenly false
                 :spacing 24
                 :halign "start"
                 :class "left"
              (power :powermenu_monitor monitor)
              ${if config.hardware.brightness-controls.enable then "(brightness)" else ""}
              (volume)
              (microphone))
            (box :space-evenly false
                 :spacing 24
                 :halign "center"
                 :class "center"
              (workspaces :monitor monitor))
            (box :space-evenly false
                 :spacing 24
                 :halign "end"
                 :class "right"
              (tray)
              ${if config.hardware.bluetooth.enable then "(bluetooth)" else ""}
              (wifi)
              (ethernet)
              (notifications)
              (memory)
              ${if config.hardware.laptop.enable then "(battery)" else ""}
              (time :calendar_monitor monitor))))
      '';
    };

    programs.networkmanager-dmenu.enable = true;
  };
}
