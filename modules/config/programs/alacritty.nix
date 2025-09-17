{ config, lib, pkgs, ... }:
let cfg = config.programs.alacritty;
in {
  options.programs.alacritty.enable = lib.mkEnableOption "alacritty";

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = [ pkgs.alacritty ];
      variables = {
        WINIT_HIDPI_FACTOR = 1;
        WINIT_X11_SCALE_FACTOR = 1;
      };
    };

    home-files.allUsers.".config/alacritty/alacritty.toml" = (
      (pkgs.formats.toml {}).generate
      "alacritty.toml"
      {
        colors = {
          primary = {
            foreground = "#c6c8d1";
            background = "#161821";
            dim_foreground = "#c6c8d1";
            bright_foreground = "None";
          };
          cursor = {
            text = "#161821";
            cursor = "#c6c8d1";
          };
          vi_mode_cursor = {
            text = "#161821";
            cursor = "#c6c8d1";
          };
          search = {
            matches = {
              foreground = "#392313";
              background = "#e4aa80";
            };
            focused_match = {
              foreground = "CellBackground";
              background = "CellForeground";
            };
          };
          hints = {
            start = {
              foreground = "#161821";
              background = "#e9b189";
            };
            end = {
              foreground = "#161821";
              background = "#e9b189";
            };
          };
          line_indicator = {
            foreground = "#161821";
            background = "#a093c7";
          };
          footer_bar = {
            foreground = "#c6c8d1";
            background = "#161821";
          };
          selection = {
            text = "CellForeground";
            background = "#272c42";
          };
          normal = {
            black = "#1e2132";
            red = "#e27878";
            green = "#b4be82";
            yellow = "#e2a478";
            blue = "#84a0c6";
            magenta = "#a093c7";
            cyan = "#89b8c2";
            white = "#c6c8d1";
          };
          bright = {
            black = "#6b7089";
            red = "#e98989";
            green = "#c0ca8e";
            yellow = "#e9b189";
            blue = "#91acd1";
            magenta = "#ada0d3";
            cyan = "#95c4ce";
            white = "#d2d4de";
          };
          dim = {
            black = "#1e2132";
            red = "#e27878";
            green = "#b4be82";
            yellow = "#e2a478";
            blue = "#84a0c6";
            magenta = "#a093c7";
            cyan = "#89b8c2";
            white = "#c6c8d1";
          };
          transparent_background_colors = false;
          draw_bold_text_with_bright_colors = false;
        };
        cursor = {
          style = {
            shape = "Block";
            blinking = "Off";
          };
          vi_mode_style = {
            shape = "Block";
            blinking = "Never";
          };
          blink_interval = 750;
          blink_timeout = 0;
          unfocused_hollow = true;
          thickness = 0.1;
        };
        font = {
          normal.family = "MartianMono Nerd Font";
          size = 13;
          offset.y = 2;
          glyph_offset.y = 1;
        };
        hints.enabled = [
          {
            regex = "(ipfs:|ipns:|magnet:|mailto:|gemini://|gopher://|https://|http://|news:|file:|git://|ssh:|ftp://)[^\\u0000-\\u001F\\u007F-\\u009F<>\"\\\\s{-}\\\\^⟨⟩`]+";
            hyperlinks = true;
            post_processing = true;
            persist = false;
            command = "xdg-open";
            binding = { key = "H"; mods = "Control|Shift"; };
            mouse = { mods = "Control"; enabled = true; };
          }
        ];
        keyboard.bindings = [
          { key = "Space"; mods = "Control|Shift"; mode = "~Search"; action = "ReceiveChar"; }
          { key = "B"; mods = "Control|Shift"; mode = "~Search"; action = "ReceiveChar"; }
          { key = "F"; mods = "Control|Shift"; mode = "~Search"; action = "ReceiveChar"; }
          { key = "Enter"; mods = "Control|Shift"; action = "CreateNewWindow"; }
        ];
        mouse.hide_when_typing = true;
        scrolling = {
          history = 15000;
          multiplier = 3;
        };
        terminal.osc52 = "CopyPaste";
        window.dimensions = {
          columns = 80;
          lines = 30;
        };
      }
    ).overrideAttrs (finalAttrs: prevAttrs: {
      buildCommand = lib.concatStringsSep "\n" [
        prevAttrs.buildCommand
        "substituteInPlace \"$out\" --replace '\\\\' '\\'"
      ];
    });
  };
}
