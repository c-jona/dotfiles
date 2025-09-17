{ self, nixpkgs, ... }@inputs:
let
  inherit (builtins) mapAttrs;
  inherit (self.lib) importNixFilesWithArgs';
  inherit (nixpkgs.lib) nixosSystem;
in
  mapAttrs (system_name: system_module:
    nixosSystem {
      modules = [
        { networking.hostName = system_name; }
        system_module
      ];
    }
  ) (importNixFilesWithArgs' inputs ./.)
