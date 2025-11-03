{ config, lib , pkgs, ... }:
let cfg = config.programs.helix;
in {
  options.programs.helix.enable = lib.mkEnableOption "helix";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.helix ];

    home-files.allUsers.".config/helix" = builtins.mapAttrs (pkgs.formats.toml {}).generate {
      "config.toml" = {
        editor = {
          auto-completion = false;
          auto-format = false;
          auto-pairs = false;
          bufferline = "multiple";
          color-modes = true;
          cursor-shape = {
            insert = "bar";
            normal = "block";
            select = "block";
          };
          inline-diagnostics = {
            cursor-line = "hint";
            max-wrap = 0;
          };
          line-number = "relative";
          lsp = {
            auto-signature-help = false;
            display-color-swatches = false;
            display-signature-help-docs = false;
          };
          rulers = [ 120 ];
          scrolloff = 3;
          soft-wrap = {
            enable = true;
            max-indent-retain = 0;
            max-wrap = 0;
            wrap-indicator = "";
          };
          statusline = {
            diagnostics = [ "hint" "info" "warning" "error" ];
            workspace-diagnostics = [ "hint" "info" "warning" "error" ];
          };
          text-width = 120;
          whitespace = {
            characters = {
              nbsp = "⍽";
              newline = "¬";
              nnbsp = "␣";
              space = "·";
              tab = "⏵";
              tabpad = " ";
            };
            render = "all";
          };
        };
        theme = "iceberg";
      };
      "languages.toml" = {
        language-server = {
          pylsp = {
            command = "pylsp";
            config.pylsp.plugins.ruff.enabled = true;
          };
        };
      };
    } // {
      "themes/iceberg.toml" = ''
        "attribute" = "green"
        "type" = "blue"
        "constructor" = "normal-fg"
        "constant" = "magenta"
        "string" = "cyan"
        "string.special" = "green"
        "comment" = "dim-fg"
        "variable" = "normal-fg"
        "variable.builtin" = "blue"
        "label" = "green"
        "punctuation" = "normal-fg"
        "punctuation.special" = "green"
        "keyword" = "blue"
        "operator" = "normal-fg"
        "function" = "function-fg"
        "tag" = "blue"
        "namespace" = "blue"
        "special" = "green"
        "markup.normal" = "normal-fg"
        "markup.heading" = "yellow"
        "markup.list" = "normal-fg"
        "markup.list.checked" = "red"
        "markup.bold" = { modifiers = [ "bold" ] }
        "markup.italic" = { modifiers = [ "italic" ] }
        "markup.strikethrough" = { modifiers = [ "crossed_out" ] }
        "markup.link.url" = { fg = "blue", underline = { color = "blue", style = "line" } }
        "markup.link.label" = "magenta"
        "markup.link.text" = "cyan"
        "markup.quote" = "normal-fg"
        "markup.raw.inline" = "magenta"
        "markup.raw.block" = "dim-fg"
        "diff.plus" = "green"
        "diff.minus" = "red"
        "diff.delta" = "cyan"

        "ui.background" = { bg = "normal-bg", fg = "normal-fg" }
        "ui.background.separator" = "dim-fg"
        "ui.cursor" = { bg = "normal-bg", fg = "dim-fg", modifiers = [ "reversed" ] }
        "ui.cursor.match" = { bg = "match-bg", fg = "bright-fg" }
        "ui.cursor.primary" = { bg = "normal-bg", fg = "normal-fg", modifiers = [ "reversed" ] }
        "ui.debug.breakpoint" = "red"
        "ui.debug.active" = "yellow"
        "ui.gutter" = { bg = "bright-bg", fg = "gutter-fg" }
        "ui.gutter.selected" = { bg = "selected-bg", fg = "bright-fg" }
        "ui.linenr" = "gutter-fg"
        "ui.linenr.selected" = { fg = "bright-fg", modifiers = [ "bold" ] }
        "ui.statusline" = { bg = "dim-bg", fg = "dim-fg" }
        "ui.statusline.inactive" = { bg = "dim-bg", fg = "match-bg" }
        "ui.statusline.normal" = { bg = "dim-bg", fg = "dim-fg", modifiers = [ "bold" ] }
        "ui.statusline.insert" = { bg = "dim-bg", fg = "match-bg", modifiers = [ "bold", "reversed" ] }
        "ui.statusline.select" = { bg = "dim-bg", fg = "dim-fg", modifiers = [ "bold", "reversed" ] }
        "ui.bufferline" = { bg = "dim-bg", fg = "match-bg" }
        "ui.bufferline.active" = { bg = "dim-bg", fg = "dim-fg" }
        "ui.bufferline.background" = { bg = "dim-bg", fg = "match-bg" }
        "ui.popup" = { bg = "dim-bg" }
        "ui.picker.header" = { fg = "dim-fg" }
        "ui.picker.header.column.active" = { modifiers = [ "bold" ] }
        "ui.window" = { bg = "dim-bg", fg = "dim-bg" }
        "ui.help" = { bg = "dim-bg" }
        "ui.text" = "normal-fg"
        "ui.text.focus" = { bg = "bright-bg", modifiers = [ "bold" ] }
        "ui.text.inactive" = "dim-fg"
        "ui.text.info" = "bright-fg"
        "ui.text.directory" = "blue"
        "ui.virtual.ruler" = { bg = "bright-bg" }
        "ui.virtual.whitespace" = "whitespace-fg"
        "ui.virtual.indent-guide" = "match-bg"
        "ui.virtual.inlay-hint" = "match-bg"
        "ui.virtual.wrap" = "match-bg"
        "ui.virtual.jump-label" = { fg = "bright-fg", modifiers = [ "bold" ] }
        "ui.menu" = { bg = "dim-bg", fg = "normal-fg" }
        "ui.menu.selected" = { bg = "selected-bg", fg = "bright-fg" }
        "ui.selection" = { bg = "selection-bg" }
        "ui.highlight" = { bg = "bright-bg" }
        "ui.cursorline.primary" = { bg = "bright-bg" }
        "ui.cursorline.secondary" = { bg = "bright-bg" }
        "ui.cursorcolumn.primary" = { bg = "bright-bg" }
        "ui.cursorcolumn.secondary" = { bg = "bright-bg" }

        "hint" = "blue"
        "info" = "cyan"
        "warning" = "yellow"
        "error" = "red"

        "diagnostic.hint" = { underline = { color = "blue", style = "curl" } }
        "diagnostic.info" = { underline = { color = "cyan", style = "curl" } }
        "diagnostic.warning" = { underline = { color = "yellow", style = "curl" } }
        "diagnostic.error" = { underline = { color = "red", style = "curl" } }
        "diagnostic.unnecessary" = { modifiers = [ "dim" ] }
        "diagnostic.deprecated" = { modifiers = [ "crossed_out" ] }

        "tabstop" = "match-bg"

        [palette]
        default = "#c6c8d1"
        black = "#1e2132"
        red = "#e27878"
        green = "#b4be82"
        yellow = "#e2a478"
        blue = "#84a0c6"
        magenta = "#a093c7"
        cyan = "#89b8c2"
        light-gray = "#c6c8d1"
        gray = "#6b7089"
        light-red = "#e98989"
        light-green = "#c0ca8e"
        light-yellow = "#e9b189"
        light-blue = "#91acd1"
        light-magenta = "#ada0d3"
        light-cyan = "#95c4ce"
        white = "#d2d4de"

        normal-bg = "#161821"
        bright-bg = "#1e2132"
        dim-bg = "#0f1117"
        match-bg = "#3e445e"
        selected-bg = "#2a3158"
        selection-bg = "#272c42"

        normal-fg = "#c6c8d1"
        bright-fg = "#cdd1e6"
        dim-fg = "#6b7089"
        gutter-fg = "#444b71"
        whitespace-fg = "#242940"
        function-fg = "#a3adcb"
      '';
    };
  };
}
