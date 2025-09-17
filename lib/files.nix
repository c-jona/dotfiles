{ self, nixpkgs, ... }:
let
  inherit (builtins)
    attrNames
    concatMap
    elemAt
    filter
    functionArgs
    isFunction
    listToAttrs
    mapAttrs
    match
    pathExists
    readDir
    readFileType
    seq
    stringLength
    substring
    ;

  inherit (self.lib) attrsToTree;
  inherit (nixpkgs.lib) filterAttrs mapAttrs' mapAttrsRecursive;
in rec {
  isDirectory = path:
    readFileType path == "directory";

  isRegularFile = path:
    readFileType path == "regular";

  isSymlink = path:
    readFileType path == "symlink";

  isUnknown = path:
    readFileType path == "unknown";

  splitFilename = path:
    let
      filename = baseNameOf path;
      split_filename = match "^(\\.?.+)\\.(.*)$" filename;
    in
      if split_filename != null then split_filename else [ filename "" ];

  getFilenameWithoutExtension = path:
    elemAt (splitFilename path) 0;

  getFileExtension = path:
    elemAt (splitFilename path) 1;

  hasFileExtension = extension: path:
    extension == getFileExtension path;

  getFile = path: name:
    if pathExists (path + "/${name}")
    then /. + path + "/${name}"
    else null;

  getRelativePath = base_path: path:
    let
      base_path' = (toString (/. + base_path)) + (
        if /. + base_path != /. then "/" else ""
      );
      path' = (toString (/. + path));
      base_path_length = stringLength base_path';
      path_length = stringLength path';
    in
      seq (pathExists base_path) (seq (pathExists path) (
        if substring 0 base_path_length path' == base_path'
        then substring base_path_length (path_length - base_path_length) path'
        else ""
      ));

  hasDefaultNix = path:
    let path' = path + "/default.nix";
    in
      pathExists path && pathExists path' && isRegularFile path';

  isDefaultNix = path:
    isRegularFile path && baseNameOf path == "default.nix";

  isNixFile = path:
    hasDefaultNix path || isRegularFile path && hasFileExtension "nix" path;

  getNixFile = path: name:
    let
      file_dir = path + "/${name}";
      file_reg = path + "/${name}.nix";
    in
      if hasDefaultNix file_dir
      then /. + file_dir
      else if pathExists file_reg && isRegularFile file_reg
      then /. + file_reg
      else null;

  getCanonNixFileName = path:
    if hasDefaultNix path
    then baseNameOf path
    else getFilenameWithoutExtension path;

  getRelativeCanonNixPath = base_path: path:
    let
      base_path' = (toString (/. + base_path)) + (
        if /. + base_path != /. then "/" else ""
      );
      path' = (toString (/. + path));
      base_path_length = stringLength base_path';
      path_length = stringLength path';
    in
      seq (pathExists base_path) (seq (pathExists path) (
        if substring 0 base_path_length path' == base_path'
        then
          (substring
            base_path_length
            (path_length - base_path_length - stringLength (baseNameOf path))
            path'
          ) + getCanonNixFileName path
        else ""
      ));

  safeReadDir = path:
    if pathExists path && readFileType path == "directory"
    then readDir path
    else {};

  getFiles = path:
    map (name: /. + path + "/${name}") (attrNames (safeReadDir path));

  getFiles' = path:
    listToAttrs (map (path:
      { name = baseNameOf path; value = path; }
    ) (getFiles path));

  getFilesRecursive = path:
    concatMap (path: [ path ] ++ getFilesRecursive path) (getFiles path);

  getFilesRecursive' = path:
    listToAttrs (map (path':
      { name = getRelativePath path path'; value = path'; }
    ) (getFilesRecursive path));

  getFilesRecursive'' = path:
    attrsToTree "/" (mapAttrs (_: path:
      if isDirectory path then {} else path
    ) (getFilesRecursive' path));

  getNonNixFiles = path:
    filter (path: isDirectory path || !isNixFile path) (getFiles path);

  getNonNixFiles' = path:
    listToAttrs (map (path:
      { name = baseNameOf path; value = path; }
    ) (getNonNixFiles path));

  getNonNixFilesRecursive = path:
    filter (path: isDirectory path || !isNixFile path) (getFilesRecursive path);

  getNonNixFilesRecursive' = path:
    listToAttrs (map (path':
      { name = getRelativePath path path'; value = path'; }
    ) (getNonNixFilesRecursive path));

  getNonNixFilesRecursive'' = path:
    attrsToTree "/" (mapAttrs (_: path:
      if isDirectory path then {} else path
    ) (getNonNixFilesRecursive' path));

  getNixFiles = path:
    filter (path: isNixFile path && !isDefaultNix path) (getFiles path);

  getNixFiles' = path:
    listToAttrs (map (path:
      { name = getCanonNixFileName path; value = path; }
    ) (getNixFiles path));

  getNixFilesRecursive = path:
    filter (path: isNixFile path && !isDefaultNix path) (getFilesRecursive path);

  getNixFilesRecursive' = path:
    listToAttrs (map (path':
      { name = getRelativeCanonNixPath path path'; value = path'; }
    ) (getNixFilesRecursive path));

  getNixFilesRecursive'' = path:
    attrsToTree "/" (mapAttrs' (name: value:
      if isDirectory value && getNixFilesRecursive value != []
      then { name = name + "/default"; value = value + "/default.nix"; }
      else { inherit name value; }
    ) (getNixFilesRecursive' path));

  importWithArgs = args: path:
    let e = import path;
    in
      if isFunction e && removeAttrs (filterAttrs (_: hasDefault: !hasDefault)
                         (functionArgs e)) (attrNames args) == {}
      then e args
      else e;

  importNixFile = path: name:
    import (getNixFile path name);

  importNixFileWithArgs = args: path: name:
    importWithArgs args (getNixFile path name);

  importNixFiles = path:
    map import (getNixFiles path);

  importNixFiles' = path:
    mapAttrs (_: import) (getNixFiles' path);

  importNixFilesRecursive = path:
    map import (getNixFilesRecursive path);

  importNixFilesRecursive' = path:
    mapAttrs (_: import) (getNixFilesRecursive' path);

  importNixFilesRecursive'' = path:
    mapAttrsRecursive (_: import) (getNixFilesRecursive'' path);

  importNixFilesWithArgs = args: path:
    map (importWithArgs args) (getNixFiles path);

  importNixFilesWithArgs' = args: path:
    mapAttrs (_: importWithArgs args) (getNixFiles' path);

  importNixFilesWithArgsRecursive = args: path:
    map (importWithArgs args) (getNixFilesRecursive path);

  importNixFilesWithArgsRecursive' = args: path:
    mapAttrs (_: importWithArgs args) (getNixFilesRecursive' path);

  importNixFilesWithArgsRecursive'' = args: path:
    mapAttrsRecursive (_: importWithArgs args) (getNixFilesRecursive'' path);
}
