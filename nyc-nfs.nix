{ lib, pkgs, ... }:
{
  # Direct LAN NFSv3 avoids Artemis's TCP-only BCH tunnel.
  services.nfs.server.extraNfsdConfig = "udp=y";
  # --timeout=0: never expire. Expiry racing a bubblewrap recursive bind of / (Codex sandbox) hangs
  # the sandboxed process in autofs_expire_wait (NYC-lab logbook #19, 2026-10-12).
  services.autofs.autoMaster = ''
    /net-local -hosts --timeout=0
    /net-nyc ${pkgs.writeText "auto-net-nyc" ''
      artemis -fstype=nfs,rw,hard,vers=3,proto=tcp,resvport,nosuid 192.168.86.199:/System/Volumes/Data/Users/rudolphpienaar
    ''} --timeout=0
  '';
}
