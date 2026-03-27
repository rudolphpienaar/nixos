{ pkgs }:

{
  bzflag = {
    name = "BZFlag";
    comment = "3D tank battle game";
    exec = "${pkgs.bzflag}/bin/bzflag";
    terminal = false;
    categories = [ "Game" "ActionGame" ];
  };

  fsv = {
    name = "FSV";
    comment = "3D filesystem visualizer";
    exec = "${pkgs.fsv}/bin/fsv";
    terminal = false;
    categories = [ "System" "Utility" ];
  };

  waydroid = {
    name = "Waydroid";
    comment = "Android container full UI";
    exec = "/home/rudolph/.local/bin/waydroid-launch";
    terminal = false;
    categories = [ "System" "Utility" ];
  };
}
