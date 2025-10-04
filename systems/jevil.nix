{ self, ... }:
{ config, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    self.nixosModules.config
  ];

  boot = {
    blacklistedKernelModules = [ "wdat_wdt" ];
    extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];
    initrd.kernelModules = [ "nvidia" ];
  };

  hardware = {
    bluetooth.enable = true;
    cpu.amd.updateMicrocode = true;
    enableRedistributableFirmware = true;
    graphics.enable = true;
    nvidia.open = false;
    xpadneo.enable = true;
  };

  services.xserver = {
    videoDrivers = [ "nvidia" ];
    xrandrHeads = [
      {
        output = "DP-1";
        primary = true;
      }
      {
        output = "HDMI-A-1";
        primary = false;
        monitorConfig = ''
          Option "RightOf" "DP-1"
        '';
      }
    ];
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.05";
}
