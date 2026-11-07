{ pkgs, ... }:

{
  imports = [
    ./modules/workstation.nix
    ./nyc-nfs.nix
    ./hardware-configuration.nix
    ./hardware/minisforum.nix
    ./hardware/nexdock.nix
  ];

  # Let the Radeon 890M borrow up to 76 GiB of system RAM (default: half of RAM).
  # A ceiling on GPU allocations, not a boot-time reservation.
  boot.kernelParams = [
    "pcie_aspm=off"
    "ttm.pages_limit=19922944"
  ];

  networking.hostName = "callisto";

  networking.firewall.allowedTCPPorts = [
    111
    2049
    4000
    4001
    4002
    20048
    24800
    11434
    3000
    11435
    11436
    11437
    18000
    18001
  ]; # 1143x/1800x: NYC-lab model-server tunnels (olympus, titan, jamsil)
  networking.firewall.allowedUDPPorts = [
    111
    2049
    4000
    4001
    4002
    20048
  ];

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

  systemd.services.wifi-runtime-powersave-off = {
    description = "Disable runtime Wi-Fi powersave for MT7925e";
    after = [ "NetworkManager.service" ];
    wants = [ "NetworkManager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.iw}/bin/iw dev wlp194s0 set power_save off";
    };
  };

  environment.etc."NetworkManager/dnsmasq.d/tch-harvard.conf".text = ''
    server=/tch.harvard.edu/134.174.12.1
    server=/tch.harvard.edu/134.174.12.2
  '';

  boot.extraModprobeConfig = ''
    options mt7925e disable_aspm=1
  '';

  users.users.toor.initialPassword = "toor";
  system.stateVersion = "25.11";
}
