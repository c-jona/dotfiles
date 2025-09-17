{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }@inputs:
  let
    forAllSystems = nixpkgs.lib.genAttrs [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-darwin"
      "x86_64-linux"
    ];

    mkOutput = (import ./lib/files.nix inputs).importNixFileWithArgs inputs ./.;
  in {
    lib = mkOutput "lib";
    nixosConfigurations = mkOutput "systems";
    nixosModules = mkOutput "modules";
    overlays = mkOutput "overlays" // {
      default = final: prev: (mkOutput "packages") prev.system;
    };
    packages = forAllSystems (mkOutput "packages");
  };
}
