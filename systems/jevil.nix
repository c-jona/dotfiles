{ self, ... }:
{ config, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    self.nixosModules.config
  ];

  boot = {
    blacklistedKernelModules = [ "sp5100_tco" ];
    initrd.kernelModules = [ "nvidia" ];
  };

  hardware = {
    bluetooth.enable = true;
    cpu.amd.updateMicrocode = true;
    enableRedistributableFirmware = true;
    graphics.enable = true;
    nvidia = {
      modesetting.enable = true;
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.latest;
      powerManagement.enable = true;
    };
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
