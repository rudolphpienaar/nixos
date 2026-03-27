{ pkgs, ... }:

{
  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Numix-Circle-Light";
      package = pkgs.numix-icon-theme-circle;
    };
  };
}
