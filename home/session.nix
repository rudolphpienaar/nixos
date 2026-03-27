{ ... }:

{
  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    GROFF_NO_SGR = "1";
    LESS = "-RX";
    LESS_TERMCAP_mb = "\\e[1;32m";
    LESS_TERMCAP_md = "\\e[1;32m";
    LESS_TERMCAP_me = "\\e[0m";
    LESS_TERMCAP_se = "\\e[0m";
    LESS_TERMCAP_so = "\\e[01;33m";
    LESS_TERMCAP_ue = "\\e[0m";
    LESS_TERMCAP_us = "\\e[1;4;31m";
    MOST_OPTS = "-X";
    PAGER = "most";
    SPLASH_WEATHER_LOCATION = "Boston";
  };
}
