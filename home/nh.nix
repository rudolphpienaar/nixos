{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  installer = pkgs.writeShellApplication {
    name = "nsi";
    runtimeInputs = [
      pkgs.nix
      pkgs.nh
      pkgs.python3
    ];
    text = ''
      exec ${pkgs.python3}/bin/python3 ${./files/nsi.py} \
        ${lib.escapeShellArg config.programs.nh.osFlake} \
        ${lib.escapeShellArg osConfig.networking.hostName} "$@"
    '';
  };
in
{
  home.file.".local/bin/nsi" = {
    source = "${installer}/bin/nsi";
    executable = true;
  };

  programs.nh = {
    enable = true;
    osFlake = "/home/rudolph/dev/nixos";
    clean.enable = true;
    clean.extraArgs = "--keep-since 14d --keep 5";
  };
}
