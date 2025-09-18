{ self, ... }:
{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    self.nixosModules.config
  ];

  boot = {
    blacklistedKernelModules = [ "iTCO_wdt" ];
    initrd.kernelModules = [ "i915" ];
    kernelModules = [ "kvm-intel" ];
  };

  hardware = {
    bluetooth.enable = true;
    brightness-controls.enable = true;
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
    graphics.enable = true;
    laptop.enable = true;
    xpadneo.enable = true;
  };

  services.xserver = {
    videoDrivers = [ "modesetting" ];
    xrandrHeads = [
      {
        output = "eDP-1";
        primary = true;
      }
    ];
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.05";
}
