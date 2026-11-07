{ ... }:

{
  imports = [
    ../../modules/workstation.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "vendian";

  # Only Falmouth's local NFS hosts are relevant here.
  services.autofs.autoMaster = ''
    /net-local -hosts --timeout=0
  '';

  # Preserve the installer-created administrator and its existing password.
  users.users.toor = {
    uid = 1000;
    extraGroups = [ "networkmanager" ];
    openssh.authorizedKeys.keyFiles = [ ../../keys/rudolph.pub ];
  };
  users.users.rudolph.openssh.authorizedKeys.keyFiles = [ ../../keys/rudolph.pub ];

  # These describe initial installations, not the current package versions.
  system.stateVersion = "26.05";
  home-manager.users.rudolph.home.stateVersion = "26.05";
}
