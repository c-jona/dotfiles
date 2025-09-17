{ config, lib, pkgs, ... }:
let cfg = config.services.xserver.dunst;
in {
  options.services.xserver.dunst.enable = lib.mkEnableOption "dunst";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      dunst
      libnotify
    ];

    home-files.allUsers.".config/dunst/dunstrc" = lib.generators.toINI {} {
      global = {
        alignment = "left";
        always_run_script = true;
        browser = "xdg-open";
        class = "Dunst";
        corner_radius = 10;
        corners = "all";
        dmenu = "rofi -dmenu -p actions";
        ellipsize = "end";
        enable_posix_regex = true;
        enable_recursive_icon_lookup = true;
        follow = "none";
        font = "monospace 16px";
        format = "\"<b>%s</b>\\n%b\"";
        frame_color = "\"#07080a\"";
        frame_width = 1;
        gap_size = 6;
        height = "(0, 180)";
        hide_duplicate_count = false;
        history_length = 20;
        horizontal_padding = 12;
        icon_corner_radius = 0;
        icon_corners = "all";
        icon_position = "off";
        icon_theme = "MoreWaita";
        ignore_dbusclose = false;
        ignore_newline = false;
        indicate_hidden = true;
        line_height = 0;
        markup = "full";
        max_icon_size = 128;
        min_icon_size = 32;
        monitor = 0;
        notification_limit = 5;
        mouse_left_click = "do_action, close_current";
        mouse_middle_click = "close_all";
        mouse_right_click = "close_current";
        offset = "(6, 6)";
        origin = "top-right";
        padding = 12;
        progress_bar = true;
        progress_bar_corner_radius = 5;
        progress_bar_corners = "all";
        progress_bar_frame_width = 1;
        progress_bar_height = 12;
        progress_bar_horizontal_alignment = "center";
        progress_bar_max_width = 296;
        progress_bar_min_width = 296;
        scale = 1;
        separator_color = "frame";
        separator_height = 0;
        show_age_threshold = "-1";
        show_indicators = false;
        sort = "id";
        stack_duplicates = true;
        sticky_history = true;
        text_icon_padding = 12;
        title = "Dunst";
        transparency = 0;
        vertical_alignment = "center";
        width = 320;
      };
      experimental = {
        per_monitor_dpi = false;
      };
      urgency_low = {
        background = "\"#0f1117\"";
        foreground = "\"#c6c8d1\"";
        highlight = "\"#c6c8d1\"";
        timeout = 3;
      };
      urgency_normal = {
        background = "\"#0f1117\"";
        foreground = "\"#c6c8d1\"";
        highlight = "\"#c6c8d1\"";
        override_pause_level = 30;
        timeout = 3;
      };
      urgency_critical = {
        background = "\"#e27878\"";
        foreground = "\"#161821\"";
        highlight = "\"#161821\"";
        override_pause_level = 60;
        timeout = 0;
      };
      transient_history_ignore = {
        match_transient = true;
        history_ignore = true;
      };
    };

    services.xserver.displayManager.sessionCommands = ''
      dunst &
    '';
  };
}
