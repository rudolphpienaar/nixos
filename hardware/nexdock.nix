{ ... }:

{
  services.udev.extraRules = ''
    # Keep the NexDock USB hub/input path awake so the lock screen can
    # immediately receive keyboard events after the dock wakes.
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1a40", ATTR{idProduct}=="0101", TEST=="power/control", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1c4f", ATTR{idProduct}=="007c", TEST=="power/control", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="27c0", ATTR{idProduct}=="0819", TEST=="power/control", ATTR{power/control}="on"

    # NexDock touchscreen: inverse of the measured single-panel X error fit
    # from 50 samples across 10%-70% of a 1920px-wide panel.
    ACTION=="add|change", SUBSYSTEM=="input", KERNEL=="event*", \
      ATTRS{idVendor}=="27c0", ATTRS{idProduct}=="0819", \
      ENV{LIBINPUT_CALIBRATION_MATRIX}="1.0060 0 -0.0083 0 1 0"
  '';
}
