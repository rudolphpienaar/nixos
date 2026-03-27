{ pkgs, ... }:

{
  home.file.".local/bin/waydroid-launch" = {
    source = ./files/waydroid-launch;
    executable = true;
  };

  xdg.desktopEntries = import ./generated-desktop-entries.nix { inherit pkgs; };
}
