{ config, ... }:

{
  xdg.configFile."avim".source =
    config.lib.file.mkOutOfStoreSymlink "/home/rudolph/dev/avim";
}
