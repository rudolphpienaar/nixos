{ pkgs, starship-config, ... }:

{
  home.packages = [ pkgs.starship ];

  # Startup must not wait for unavailable NFS filesystems.
  home.file.".splash".source = pkgs.writeText "startup-splash" (
    builtins.replaceStrings
      [ "  cpufetch\n" "  neofetch --disable WM --disable Resolution 2>/dev/null" "  screenfetch 2>/dev/null" ]
      [ "  ${pkgs.coreutils}/bin/timeout -k 1 4 cpufetch || true\n"
        "  ${pkgs.coreutils}/bin/timeout -k 1 4 neofetch --disable WM Resolution Disk 2>/dev/null || true"
        "  ${pkgs.coreutils}/bin/timeout -k 1 4 screenfetch -d '-disk' 2>/dev/null || true" ]
      (builtins.readFile (starship-config + "/home/.splash"))
  );

  xdg.configFile = {
    "starship.toml".source = starship-config + "/home/.config/starship.toml";
    "starship-2line.toml".source = starship-config + "/home/.config/starship-2line.toml";
    "starship-3line.toml".source = starship-config + "/home/.config/starship-3line.toml";
    "starship-nopills.toml".source = starship-config + "/home/.config/starship-nopills.toml";
    "starship-gh-status.sh".source = starship-config + "/home/.config/starship-gh-status.sh";
    "starship-system-status.sh".source = starship-config + "/home/.config/starship-system-status.sh";
    "starship-theme.zsh".source = starship-config + "/home/.config/starship-theme.zsh";
  };
}
