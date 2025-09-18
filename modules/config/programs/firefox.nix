{
  programs.firefox = {
    autoConfig = ''
      lockPref("findbar.highlightAll", true);
      lockPref("font.default.x-western", "sans-serif");
      lockPref("full-screen-api.transition-duration.enter", "0 0");
      lockPref("full-screen-api.transition-duration.leave", "0 0");
      lockPref("full-screen-api.transition.timeout", 0);
      lockPref("full-screen-api.warning.timeout", 0);
      lockPref("sidebar.backupState", '{"launcherExpanded":false}');
      lockPref("sidebar.revamp", true);
      lockPref("sidebar.verticalTabs", true);
      lockPref("sidebar.main.tools", "history,bookmarks");
    '';
    policies = {
      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;
      DisableFirefoxScreenshots = true;
      DisableFirefoxStudies = true;
      DisableFormHistory = true;
      DisablePocket = true;
      DisableSetDesktopBackground = true;
      DisableTelemetry = true;
      DisplayBookmarksToolbar = "never";
      DisplayMenuBar = "default-off";
      DNSOverHTTPS = {
        Enabled = true;
        Fallback = false;
        Locked = true;
      };
      DontCheckDefaultBrowser = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
      ExtensionSettings =
        let extension = { short_id, uuid }:
          {
            name = uuid;
            value = {
              install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${short_id}/latest.xpi";
              installation_mode = "force_installed";
              private_browsing = true;
            };
          };
        in builtins.listToAttrs (map extension [
          { short_id = "iceberg-darker"; uuid = "{11987003-9435-4f9d-919e-8720ebb6a64b}"; }
          { short_id = "istilldontcareaboutcookies"; uuid = "idcac-pub@guus.ninja"; }
          { short_id = "ublock-origin"; uuid = "uBlock0@raymondhill.net"; }
          { short_id = "youtube-nonstop"; uuid = "{0d7cafdd-501c-49ca-8ebb-e3341caaa55e}"; }
        ]);
      ExtensionUpdate = true;
      FirefoxHome = {
        Search = true;
        TopSites = false;
        SponsoredTopSites = false;
        Highlights = false;
        Pocket = false;
        Stories = false;
        SponsoredPocket = false;
        SponsoredStories = false;
        Snippets = false;
        Locked = true;
      };
      HttpsOnlyMode = "force_enabled";
      NoDefaultBookmarks = true;
      PasswordManagerEnabled = false;
      Permissions = {
        Notifications = {
          BlockNewRequests = true;
          Locked = true;
        };
        VirtualReality = {
          BlockNewRequests = true;
          Locked = true;
        };
      };
      PictureInPicture = {
        Enabled = false;
        Locked = true;
      };
      PopupBlocking = {
        Default = true;
        Locked = true;
      };
      Preferences =
        let
          default = value:
            {
              Value = value;
              Status = "default";
            };

          locked = value:
            {
              Value = value;
              Status = "locked";
            };
        in builtins.mapAttrs (_: default) {
          "browser.uiCustomization.horizontalTabstrip" = ''["tabbrowser-tabs","new-tab-button"]'';
          "browser.uiCustomization.state" = ''{"placements":{"widget-overflow-fixed-list":[],"unified-extensions-area":["ublock0_raymondhill_net-browser-action"],"nav-bar":["sidebar-button","back-button","forward-button","stop-reload-button","urlbar-container","vertical-spacer","zoom-controls","downloads-button","unified-extensions-button"],"toolbar-menubar":["menubar-items"],"TabsToolbar":[],"vertical-tabs":["tabbrowser-tabs"],"PersonalToolbar":["import-button","personal-bookmarks"]},"seen":["developer-button","ublock0_raymondhill_net-browser-action"],"dirtyAreaCache":["nav-bar","TabsToolbar","vertical-tabs","PersonalToolbar","toolbar-menubar","unified-extensions-area"],"currentVersion":22,"newElementCount":3}'';
        } // builtins.mapAttrs (_: locked) {
          "accessibility.typeaheadfind.enablesound" = false;
          "browser.aboutConfig.showWarning" = false;
          "browser.eme.ui.enabled" = true;
          "browser.preferences.moreFromMozilla" = false;
          "browser.quitShortcut.disabled" = true;
          "browser.sessionstore.resume_from_crash" = false;
          "browser.startup.couldRestoreSession.count" = 0;
          "browser.tabs.inTitlebar" = 0;
          "browser.urlbar.showSearchSuggestionsFirst" = false;
          "browser.urlbar.suggest.engines" = false;
          "browser.urlbar.suggest.openpage" = false;
          "browser.urlbar.suggest.quickactions" = false;
          "browser.urlbar.suggest.recentsearches" = false;
          "browser.urlbar.suggest.topsites" = false;
          "browser.urlbar.suggest.trending" = false;
          "extensions.activeThemeID" = "{11987003-9435-4f9d-919e-8720ebb6a64b}";
          "intl.regional_prefs.use_os_locales" = true;
          "layout.spellcheckDefault" = 0;
          "layout.css.prefers-color-scheme.content-override" = 0;
          "media.eme.enabled" = true;
          "network.cookie.cookieBehavior" = 5;
          "privacy.fingerprintingProtection.pbmode" = false;
        };
      OfferToSaveLogins = false;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      SearchBar = "unified";
      SearchEngines = {
        Add = [
          {
            Name = "Youtube";
            IconURL = "https://upload.wikimedia.org/wikipedia/commons/0/09/YouTube_full-color_icon_%282017%29.svg";
            Alias = "@yt";
            Description = "Search for Youtube videos";
            Method = "GET";
            URLTemplate = "https://www.youtube.com/results?search_query={searchTerms}";
          }
          {
            Name = "Nix Packages";
            IconURL = "https://search.nixos.org/favicon.png";
            Alias = "@np";
            Description = "Search for Nix packages";
            Method = "GET";
            URLTemplate = "https://search.nixos.org/packages?from=0&size=200&sort=relevance&type=packages&query={searchTerms}";
          }
          {
            Name = "NixOS Options";
            IconURL = "https://search.nixos.org/favicon.png";
            Alias = "@no";
            Description = "Search for NixOS options";
            Method = "GET";
            URLTemplate = "https://search.nixos.org/options?from=0&size=200&sort=relevance&type=packages&query={searchTerms}";
          }
        ];
        Default = "Google";
        DefaultPrivate = "Google";
        PreventInstalls = true;
        Remove = [
          "Bing"
          "DuckDuckGo"
          "eBay"
          "Ecosia"
          "Qwant"
          "Wikipedia (en)"
        ];
      };
      SkipTermsOfUse = true;
      TranslateEnabled = false;
    };
  };
}
