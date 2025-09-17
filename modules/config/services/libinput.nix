{
  services.libinput = {
    mouse = {
      accelProfile = "flat";
      accelSpeed = "0";
    };
    touchpad = {
      accelProfile = "flat";
      accelSpeed = "0.5";
      additionalOptions = "Option \"TappingDrag\" \"off\"";
    };
  };
}
