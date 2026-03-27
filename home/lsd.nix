{ ... }:

{
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
