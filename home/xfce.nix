{ pkgs, ... }:

{
  home.packages = [ pkgs.xfconf ];

  xdg.configFile."autostart/xfconfd.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Version=1.0
    Name=xfconfd
    Comment=Xfce settings daemon for non-Xfce sessions
    Exec=${pkgs.xfconf}/bin/xfconfd
    OnlyShowIn=GNOME;Unity;
    X-GNOME-Autostart-enabled=true
    NoDisplay=true
    StartupNotify=false
    Terminal=false
  '';
}
