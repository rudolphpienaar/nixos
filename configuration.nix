{ config, pkgs, ... }:

{
  imports = [
    ./nyc-nfs.nix
    ./hardware-configuration.nix
    ./hardware/minisforum.nix
    ./hardware/nexdock.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;
  # Let the Radeon 890M borrow up to 76 GiB of system RAM (default: half of RAM).
  # A ceiling on GPU allocations, not a boot-time reservation.
  boot.kernelParams = [ "pcie_aspm=off" "ttm.pages_limit=19922944" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModprobeConfig = ''
    options mt7925e disable_aspm=1
    options v4l2loopback devices=1 exclusive_caps=0 card_label="Iriun Webcam"
  '';

  networking.hostName = "callisto";
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = "dnsmasq";
  networking.networkmanager.wifi.powersave = false;
  networking.networkmanager.wifi.scanRandMacAddress = false;
  networking.networkmanager.unmanaged = [ "interface-name:waydroid0" ];
  networking.firewall.allowedTCPPorts = [ 111 2049 4000 4001 4002 20048 24800 11434 3000 11435 11436 11437 18000 18001 ];  # 1143x/1800x: NYC-lab model-server tunnels (olympus, titan, jamsil)
  networking.firewall.allowedUDPPorts = [ 111 2049 4000 4001 4002 20048 ];

  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services.xserver.enable = true;
  services.displayManager.gdm = {
    enable = true;
    # Keep boot-time services reachable while the machine waits at GDM.
    autoSuspend = false;
  };
  # This host is administered primarily over SSH and must remain reachable.
  # Refuse suspend and hibernation regardless of which desktop service asks.
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
    suspend-then-hibernate.enable = false;
  };
  services.desktopManager.gnome.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.printing.enable = true;
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
    };
  };
  services.cron.enable = true;
  services.rpcbind.enable = true;
  services.autofs = {
    enable = true;
  };
  services.nfs.server = {
    enable = true;
    statdPort = 4000;
    lockdPort = 4001;
    mountdPort = 4002;
    exports = ''
      /home 192.168.86.0/24(rw,fsid=0,no_subtree_check)
      /home/rudolph 192.168.86.199(rw,no_subtree_check,root_squash)
    '';
  };
  virtualisation.waydroid = {
    enable = true;
    package = pkgs.waydroid-nftables;
  };
  virtualisation.docker.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.groups.fnndsc = {
    gid = 1102;
  };

  users.users.rudolph = {
    isNormalUser = true;
    description = "Rudolph Pienaar";
    uid = 2090878;
    # Start enabled user services at boot, without an interactive login.
    linger = true;
    group = "fnndsc";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.zsh;
  };

  users.users.toor = {
    isNormalUser = true;
    description = "Rescue Admin";
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    initialPassword = "toor";
  };

  security.sudo.wheelNeedsPassword = false;

  programs.firefox.enable = true;
  programs.zsh.enable = true;
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    dbus
    glib
    nss
    nspr
    atk
    at-spi2-atk
    libdrm
    mesa
    alsa-lib
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (import ./overlays/iriunwebcam.nix)
    (import ./overlays/nchat-master.nix)
  ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;


  systemd.services.wifi-runtime-powersave-off = {
    description = "Disable runtime Wi-Fi powersave for MT7925e";
    after = [ "NetworkManager.service" ];
    wants = [ "NetworkManager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''${pkgs.iw}/bin/iw dev wlp194s0 set power_save off'';
    };
  };

  environment.variables = {
    GI_TYPELIB_PATH = "/run/current-system/sw/lib/girepository-1.0";
  };

  environment.etc."NetworkManager/dnsmasq.d/tch-harvard.conf".text = ''
    server=/tch.harvard.edu/134.174.12.1
    server=/tch.harvard.edu/134.174.12.2
  '';

  environment.systemPackages = with pkgs; [
    opencode
    wget
    libgtop
    gnome-system-monitor
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "pre-home-manager";
  home-manager.users.rudolph = import ./home.nix;

  system.stateVersion = "25.11";
}
