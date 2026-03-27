{ ... }:

{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      auto_sync = true;
      search_mode = "prefix";
      style = "full";
      sync_frequency = "5m";
    };
  };
}
