{ self, ... }:
{ config, lib, pkgs, ... }:
let
  inherit (builtins)
    attrValues
    concatStringsSep
    filter
    isString
    listToAttrs
    storeDir
    ;

  inherit (self.lib)
    attrsToTreeCond
    filterAttrsRecursiveCond
    isUntypedAttrs
    recursiveUpdateUntilTypedAttrs
    ;

  inherit (lib)
    fix
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    replaceStrings
    types
    ;

  filesType = with types; fix (this: attrsOf (nullOr (oneOf [ path lines this ])));
  cfg = config.home-files;
in {
  options = {
    home-files = {
      enable = mkEnableOption "home-files";
      allUsers = mkOption {
        default = {};
        description = "Generic home files for all normal users.";
        type = filesType;
      };
      perUser = mkOption {
        default = {};
        description = "Per user home files.";
        type = types.attrsOf filesType;
      };
    };
    users.users = mkOption {
      type = with types; attrsOf (submodule ({ config, ... }: {
        options.home-files = {
          enable = mkOption {
            default = config.isNormalUser;
            description = "Whether to enable home-files for this user.";
            type = types.bool;
          };
          includeGenericFiles = mkOption {
            default = true;
            description = ''
              Whether to include the generic home files for this user.
            '';
            type = types.bool;
          };
        };
      }));
    };
  };

  config = mkIf cfg.enable {
    systemd =
      let
        users =
          filter
          (user: user.home-files.enable)
          (attrValues config.users.users)
          ;

        home-files = user:
          let
            files =
              let
                allUsers =
                  if user.home-files.includeGenericFiles
                  then cfg.allUsers
                  else {};
                perUser = cfg.perUser.${user.name} or {};
              in
                attrsToTreeCond isUntypedAttrs "/" (
                  filterAttrsRecursiveCond isUntypedAttrs (_: value:
                    value != null
                  ) (recursiveUpdateUntilTypedAttrs allUsers perUser)
                );

            linkFiles = path: files:
              ''
                mkdir "$out"'/${concatStringsSep "/" path}'
                ${concatStringsSep "\n" (mapAttrsToList (name: value:
                  let path' = path ++ [ name ];
                  in
                    if isUntypedAttrs value
                    then linkFiles path' value
                    else let target =
                      if isString value
                      then pkgs.writeText name value
                      else value;
                    in ''
                      ln -sT '${target}' "$out"'/${concatStringsSep "/" path'}'
                    ''
                ) files)}
              '';
          in
            pkgs.runCommandLocal "home-files" {} (linkFiles [] files);

        home-files-setup = ''
          shopt -s dotglob globstar nullglob
          CURRENT_FILES="$(readlink -s "$XDG_STATE_HOME/home-files" || true)"
          [[ $CURRENT_FILES == "$HOME_FILES" ]] && exit

          if [[ $CURRENT_FILES == "$NIX_STORE_DIR"/*-home-files ]]; then
            removeDirs=()
            for target in "$CURRENT_FILES"/**; do
              dest="$HOME''${target:''${#CURRENT_FILES}}"
              if [[
                -L $target
                && $(readlink -s "$dest" || true) == "$target"
              ]]; then
                rm "$dest"
              elif [[
                ! -L $dest
                && -d $dest
                && ! -d "$HOME_FILES''${target:''${#CURRENT_FILES}}"
              ]]; then
                removeDirs=("$dest" "''${removeDirs[@]}")
              fi
            done
            ((''${#removeDirs[@]})) && rmdir --ignore-fail-on-non-empty "''${removeDirs[@]}"
          fi

          for target in "$HOME_FILES"/**; do
            dest="$HOME''${target:''${#HOME_FILES}}"
            if [[ -L $target ]]; then
              ln -fsT "$target" "$dest"
            else
              mkdir -p "$dest"
            fi
          done

          mkdir -p "$XDG_STATE_HOME"
          ln -fsT "$HOME_FILES" "$XDG_STATE_HOME/home-files"
        '';

        mkService = user:
          {
            name = "home-files-setup-${user.name}";
            value = {
              description = "setup home files for ${user.name}";
              environment = {
                HOME = user.home;
                HOME_FILES = "${home-files user}";
                NIX_STORE_DIR = storeDir;
                XDG_STATE_HOME = replaceStrings [ "$HOME" ] [ user.home ] (
                  config.environment.sessionVariables.XDG_STATE_HOME
                    or "$HOME/.local/state"
                );
              };
              script = home-files-setup;
              serviceConfig = {
                Type = "oneshot";
                User = user.name;
              };
              wantedBy = [ "multi-user.target" ];
            };
          };
      in {
        services = listToAttrs (map mkService users);
      };
  };
}
