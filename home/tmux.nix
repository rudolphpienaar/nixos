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
      resurrect
      continuum
    ];

    extraConfig = ''
      set -g base-index 0
      setw -g pane-base-index 0
      set -g renumber-windows on
      set -g set-clipboard off
      bind-key -T copy-mode y send-keys -X copy-selection-and-cancel
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      bind-key -T copy-mode Enter send-keys -X copy-selection-and-cancel
      bind-key -T copy-mode-vi Enter send-keys -X copy-selection-and-cancel
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
