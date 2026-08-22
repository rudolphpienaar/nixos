{ pkgs, starship-config, ... }:

{
  home.packages = [ pkgs.starship ];

  home.file.".splash".source = starship-config + "/home/.splash";

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
