{ pkgs, ... }:

{
  home.packages = with pkgs; [
    asciidoctor
    bsd-finger
    cpufetch
    clang-tools
    curl
    direnv
    dcmtk
    fd
    figlet
    fortune
    gcc
    gh
    git
    google-cloud-sdk
    lua-language-server
    most
    mc
    fastfetch
    neovim
    nil
    nix-direnv
    nixfmt-rfc-style
    nodejs_24
    powerline-go
    python3
    ripgrep
    screenfetch
    shellcheck
    shfmt
    stylua
    toilet
    unzip
    wl-clipboard
    xclip
    zsh-powerlevel10k
    fsv
    nchat
    element-desktop
    gnome-terminal
    vivaldi
    vivaldi-ffmpeg-codecs
    guake
    numix-icon-theme-circle
    gnome-tweaks
    bzflag
    bat
    # Disabled for now: current nixpkgs fetches Spotify from Snapcraft, and
    # api.snapcraft.io timeouts block unrelated system rebuilds.
    # spotify
    xfce.xfce4-terminal
    btop
    youtube-viewer
    mpv
    yt-dlp
    vscodium
    bubblewrap
    sshuttle
    speedtest-cli
    iw
    uv
    cheese
    glow
    htop
    tree
    gnumake
    jq
    pyright
    ruff
    prettier
    iamb
    rustc
    cargo
    rust-analyzer
    pkg-config
    openssl
    ollama
    libreoffice-fresh
    just
    ctop
    lazydocker
    iriunwebcam
    android-tools
    v4l-utils
    (wrapOBS {
      plugins = with obs-studio-plugins; [
        droidcam-obs
    pandoc
    poppler-utils
    tectonic
    vim
    gnome-screenshot
    flameshot
    eog
    spotify
    evince
      ];
    })
    gedit
  ];

  # Vivaldi's upstream launcher tries to self-download proprietary codecs from
  # Snapcraft when this path is missing. On NixOS we provide the codec via Nix
  # instead, avoiding a network-dependent startup path.
  home.file.".local/lib/vivaldi/media-codecs-git-2026-02-09/libffmpeg.so".source =
    "${pkgs.vivaldi-ffmpeg-codecs}/lib/libffmpeg.so";
}
