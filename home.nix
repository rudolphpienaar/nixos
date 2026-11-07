{ lib, ... }:

{
  imports = [
    ./home
  ];

  home.username = "rudolph";
  home.homeDirectory = "/home/rudolph";
  home.stateVersion = lib.mkDefault "25.11";

  programs.home-manager.enable = true;
}
