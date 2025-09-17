{ config, lib, pkgs, ... }:
let cfg = config.programs.vscode;
in lib.mkMerge [
  {
    programs.vscode = {
      extensions = with pkgs.vscode-extensions; [
        bbenoist.nix
        mkhl.direnv
      ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "iceberg-theme";
          publisher = "cocopon";
          version = "2.0.4";
          sha256 = "CZxXZPjfj6SDjeZWdP2BUpNnn3zmUWYR2/TuIrjO/3Y=";
        }
      ];
      package = pkgs.vscode-fhs;
    };
  }
  (lib.mkIf cfg.enable {
    home-files.allUsers.".config/Code/User/settings.json" = (
      (pkgs.formats.json {}).generate
      "settings.json"
      {
        "editor.autoClosingBrackets" = "never";
        "editor.bracketPairColorization.enabled" = false;
        "editor.colorDecorators" = false;
        "editor.cursorBlinking" = "solid";
        "editor.cursorSurroundingLines" = 3;
        "editor.fontFamily" = "monospace";
        "editor.fontSize" = 17;
        "editor.guides.indentation" = false;
        "editor.inlayHints.enabled" = "off";
        "editor.insertSpaces" = false;
        "editor.lightbulb.enabled" = "off";
        "editor.lineHeight" = 1.4;
        "editor.matchBrackets" = "near";
        "editor.minimap.enabled" = false;
        "editor.occurrencesHighlight" = "off";
        "editor.renderLineHighlight" = "gutter";
        "editor.renderWhitespace" = "all";
        "editor.rulers" = [ 120 ];
        "editor.selectionHighlight" = false;
        "editor.stickyScroll.enabled" = false;
        "editor.suggest.showWords" = false;
        "explorer.confirmDelete" = false;
        "explorer.decorations.colors" = false;
        "extensions.autoUpdate" = false;
        "extensions.ignoreRecommendations" = true;
        "files.insertFinalNewline" = true;
        "git.openRepositoryInParentFolders" = "always";
        "git.terminalGitEditor" = true;
        "security.workspace.trust.enabled" = false;
        "terminal.integrated.drawBoldTextInBrightColors" = false;
        "terminal.integrated.enablePersistentSessions" = false;
        "terminal.integrated.fontFamily" = "monospace";
        "terminal.integrated.fontSize" = 17;
        "terminal.integrated.lineHeight" = 1.2;
        "terminal.integrated.shellIntegration.decorationsEnabled" = "never";
        "terminal.integrated.stickyScroll.enabled" = false;
        "update.mode" = "none";
        "update.showReleaseNotes" = false;
        "window.customTitleBarVisibility" = "never";
        "window.titleBarStyle" = "native";
        "workbench.colorCustomizations" = {
          "[Iceberg]" = {
            "editorBracketMatch.background" = "#3e445e";
            "editorBracketMatch.border" = "#3e445e";
            "editorCursor.background" = "#161821";
            "editorCursor.foreground" = "#c6c8d1";
            "editorGutter.addedBackground" = "#b4be82";
            "editorGutter.background" = "#161821";
            "editorGutter.deletedBackground" = "#e27878";
            "editorGutter.modifiedBackground" = "#89b8c2";
            "editorIndentGuide.activeBackground1" = "#3e445e";
            "editorIndentGuide.background1" = "#242940";
            "editorOverviewRuler.addedForeground" = "#b4be8290";
            "editorOverviewRuler.border" = "#24294000";
            "editorOverviewRuler.deletedForeground" = "#e2787890";
            "editorOverviewRuler.infoForeground" = "#95c4ce90";
            "editorOverviewRuler.modifiedForeground" = "#89b8c290";
            "editorOverviewRuler.warningForeground" = "#e2a47890";
            "editorOverviewRuler.wordHighlightForeground" = "#84a0c690";
            "sideBarSectionHeader.background" = "#161821";
            "statusBar.background" = "#161821";
            "statusBar.noFolderBackground" = "#161821";
            "tree.inactiveIndentGuidesStroke" = "#242940";
            "tree.indentGuidesStroke" = "#3e445e";
          };
        };
        "workbench.colorTheme" = "Iceberg";
        "workbench.editor.decorations.colors" = false;
        "workbench.startupEditor" = "none";
      }
    );
  })
]
