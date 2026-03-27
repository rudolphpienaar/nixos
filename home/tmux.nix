{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    clock24 = true;
    historyLimit = 100000;
    keyMode = "vi";
    mouse = true;
    prefix = "C-b";
    sensibleOnTop = true;
    terminal = "screen-256color";

    plugins = with pkgs.tmuxPlugins; [
      sensible
      tmux-powerline
      yank
      resurrect
      continuum
      vim-tmux-navigator
    ];

    extraConfig = ''
      set -g base-index 1
      setw -g pane-base-index 1
      set -g renumber-windows on
      set -g set-clipboard on
      set -g status-position bottom
      set -g status-interval 2

      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux reloaded"

      set-environment -g TMUX_POWERLINE_CONFIG ~/.config/tmux-powerline/themes/callisto.sh
    '';
  };

  xdg.configFile."tmux-powerline/themes/callisto.sh".source = ./files/tmux-powerline-callisto.sh;
}
