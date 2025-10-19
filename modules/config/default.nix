{ self, nixpkgs-unstable, ... }@inputs:
{ config, pkgs, ... }:
{
  imports = [ self.nixosModules.home-files ] ++ self.lib.importNixFilesWithArgsRecursive inputs ./.;

  boot = {
    consoleLogLevel = 3;
    initrd = {
      systemd.enable = true;
      verbose = false;
    };
    kernelParams = [ "quiet" "udev.log_level=3" "nowatchdog" ];
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
        editor = false;
      };
      timeout = 0;
    };
  };

  console = {
    colors = [
      "161821" "e27878" "b4be82" "e2a478" "84a0c6" "a093c7" "89b8c2" "c6c8d1"
      "6b7089" "e98989" "c0ca8e" "e9b189" "91acd1" "ada0d3" "95c4ce" "d2d4de"
    ];
    earlySetup = true;
    font = "ter-v24b.psf.gz";
    packages = [ pkgs.terminus_font ];
    useXkbConfig = true;
  };

  environment = {
    etc."nixos".source = config.users.users.jona.home + "/stuff/dotfiles";
    sessionVariables = {
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";
    };
    shellAliases = {
      diff = "diff --color=auto";
      grep = "grep --color=auto";
      l = null;
      la = "ls -a";
      ll = "ls -al";
      ls = "ls -h --color=auto";
      neofetch = "fastfetch";
    };
    systemPackages = with pkgs; [
      adwaita-icon-theme
      adwaita-icon-theme-legacy
      bc
      clang
      clang-tools
      discord
      fastfetch
      feh
      gcc
      gdb
      ghc
      gnumake
      haskell-language-server
      inotify-tools
      jdk
      jdt-language-server
      jq
      krita
      mocu-xcursor
      morewaita-icon-theme
      mpv
      nil
      pinentry-gnome3
      pulsemixer
      (python3.withPackages (python-pkgs: with python-pkgs; [
        python-lsp-server
        python-lsp-ruff
      ]))
      R
      ripgrep
      rstudio
      shellcheck
      spotify
      stack
      tree
      typescript-language-server
      vscode-langservers-extracted
      wget
    ];
    variables = {
      EDITOR = "hx";
      LESS = "--RAW-CONTROL-CHARS --ignore-case --incsearch --search-options=W";
      TERMINAL = "alacritty";
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXROOT";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-label/ESP";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
  };

  fonts = {
    fontconfig.defaultFonts = {
      emoji = [ "Noto Color Emoji" ];
      monospace = [ "MartianMono Nerd Font" ];
      sansSerif = [ "Roboto" ];
      serif = [ "Roboto Slab" ];
    };
    packages = with pkgs; [
      nerd-fonts.martian-mono
      noto-fonts
      noto-fonts-color-emoji
      roboto
      roboto-slab
    ];
  };

  home-files = {
    enable = true;
    allUsers = {
      ".config" = {
        "user-dirs.conf" = "enabled=False";
        "user-dirs.dirs" = ''
          XDG_DESKTOP_DIR="$HOME/Desktop"
          XDG_DOCUMENTS_DIR="$HOME/Documents"
          XDG_DOWNLOAD_DIR="$HOME/Downloads"
          XDG_MUSIC_DIR="$HOME/Music"
          XDG_PICTURES_DIR="$HOME/Pictures"
          XDG_PUBLICSHARE_DIR="$HOME/Public"
          XDG_TEMPLATES_DIR="$HOME/Templates"
          XDG_VIDEOS_DIR="$HOME/Videos"
        '';
      };
      ".local/share/icons/default/index.theme" = ''
        [Icon Theme]
        Name=Default
        Inherits=MoreWaita
      '';
      Desktop = {};
      Documents = {};
      Downloads = {};
      Music = {};
      Pictures = {};
      Public = {};
      Templates = {};
      Videos = {};
    };
  };

  i18n = {
    defaultLocale = "en_IE.UTF-8";
    extraLocaleSettings.LC_COLLATE = "C.UTF-8";
  };

  networking.networkmanager = {
    enable = true;
    wifi = {
      powersave = false;
      scanRandMacAddress = false;
    };
  };

  nix = {
    channel.enable = false;
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "flakes" "nix-command" ];
      flake-registry = "";
      trusted-users = [ "root" "@wheel" ];
    };
  };

  nixpkgs = {
    config.allowUnfree = true;
    overlays = with self.overlays; [
      default
      fix-startx
      (final: prev: with nixpkgs-unstable.legacyPackages.${prev.system}; {
        inherit
          bzmenu
          ;
      })
    ];
  };

  programs = {
    alacritty.enable = true;
    command-not-found.enable = false;
    direnv.enable = true;
    file-roller.enable = true;
    firefox.enable = true;
    fzf.enable = true;
    git.enable = true;
    helix.enable = true;
    htop.enable = true;
    less.enable = true;
    nautilus.enable = true;
    nh.enable = true;
    nix-ld.enable = true;
    rofi.enable = true;
    steam.enable = true;
    vscode.enable = true;
  };

  security = {
    polkit = {
      enable = true;
      extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (subject.isInGroup("wheel")) {
            return polkit.Result.YES;
          }
        });
      '';
    };
    sudo.wheelNeedsPassword = false;
  };

  services = {
    enable-numlock.enable = true;
    gnome = {
      glib-networking.enable = true;
      gnome-keyring.enable = true;
      localsearch.enable = true;
      polkit-agent.enable = true;
      sushi.enable = true;
    };
    greetd.enable = true;
    gvfs.enable = true;
    libinput.enable = true;
    nh-clean.enable = true;
    pipewire.enable = true;
    preload.enable = true;
    xserver = {
      enable = true;
      clipmenu.enable = true;
      dunst.enable = true;
      numlockx.enable = true;
      picom.enable = true;
      wallpaper = {
        enable = true;
        source = ./wallpaper.jpg;
      };
      windowManager.i3.enable = true;
      xss-lock.enable = true;
    };
  };

  swapDevices = [ { device = "/dev/disk/by-label/SWAP"; } ];

  system.extraDependencies = [ pkgs.stdenv ];

  time.timeZone = "Europe/Brussels";

  users.users.jona = {
    extraGroups = [ "networkmanager" "wheel" ];
    initialPassword = "";
    isNormalUser = true;
  };

  xdg = {
    portal = {
      enable = true;
      config.common.default = "*";
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
    terminal-exec = {
      enable = true;
      settings.default = [ "Alacritty.desktop" ];
    };
  };
}
