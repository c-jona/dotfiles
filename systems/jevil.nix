{ self, ... }:
{ config, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    self.nixosModules.config
  ];

  boot = {
    blacklistedKernelModules = [ "bcma" "bcm43xx" "brcmfmac" "brcmsmac" "brcm80211" "b43" "b43legacy" "iTCO_wdt" "ssb" ];
    extraModulePackages = with config.boot.kernelPackages; [
      broadcom_sta
      nvidia_x11
    ];
    initrd.kernelModules = [ "nvidia" ];
    kernelModules = [ "kvm-intel" ];
  };

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
    graphics.enable = true;
    nvidia.open = false;
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

  nixpkgs = {
    hostPlatform = "x86_64-linux";
    config.permittedInsecurePackages = [ "broadcom-sta-6.30.223.271-57-6.12.47" ];
  };

  system.stateVersion = "25.05";
}
