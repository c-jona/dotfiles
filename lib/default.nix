{ nixpkgs, ... }@inputs:
let
  inherit (builtins) attrValues foldl';
  inherit (import ./files.nix inputs) importNixFilesWithArgs';
  inherit (nixpkgs.lib) mergeAttrs;

  lib = importNixFilesWithArgs' inputs ./.;
in
  foldl' mergeAttrs lib (attrValues lib)
