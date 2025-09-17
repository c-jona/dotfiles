{ self, nixpkgs, ... }@inputs:
system:
let
  inherit (builtins) mapAttrs;
  inherit (self.lib) importNixFilesWithArgs';
  inherit (nixpkgs.lib) callPackageWith;
in
  mapAttrs (_: pkg:
    callPackageWith (nixpkgs.legacyPackages.${system}) pkg {}
  ) (importNixFilesWithArgs' inputs ./.)
