{ ... }:

{
  programs.nh = {
    enable = true;
    osFlake = "/home/rudolph/dev/nixos";
    clean.enable = true;
    clean.extraArgs = "--keep-since 14d --keep 5";
  };
}
