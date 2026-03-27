{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    shellAliases = {
      avim = "NVIM_APPNAME=avim nvim";
      claude = "npx -y @anthropic-ai/claude-code@latest";
      codex = "npx -y @openai/codex@latest";
      gemini = "npx -y @google/gemini-cli@latest";
      llm = "npx -y @simonw/llm@latest";
      ns = "nix search nixpkgs";
      nsr = "nh os switch /home/rudolph/dev/nixos --hostname callisto";
    };

    initContent = ''
      eval "$(direnv hook zsh)"
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
      [[ -f ~/.ls_colours_bash-bgblack ]] && source ~/.ls_colours_bash-bgblack
      [[ -f ~/.config/zsh/splash.zsh ]] && source ~/.config/zsh/splash.zsh

      aview() {
        asciidoctor -b manpage "$1" -o - 2>/dev/null | man -l - 2>/dev/null | less -R
      }

      dview() {
        aview "$1" 2>/dev/null
      }

      compdef '_files' aview
      compdef '_files' dview
    '';

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" ];
    };
  };
}
