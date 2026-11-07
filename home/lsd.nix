{ ... }:

{
  home.file.".ls_colours_bash-bgblack".source = ./files/ls-colours-bash-bgblack;

  programs.lsd = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      date = "relative";
      dereference = false;
      icons = {
        theme = "fancy";
        when = "auto";
      };
      sorting = {
        dir-grouping = "first";
      };
    };
  };
}
