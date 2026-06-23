{ pkgs, ... }:

{
  systemd.user.services.forward-ssh-mercury = {
    Unit = {
      Description = "Forward SSH tunnel: localhost:4218 to mercury:4218";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.openssh}/bin/ssh -N -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o TCPKeepAlive=yes -L 127.0.0.1:4218:127.0.0.1:4218 mercury";
      Restart = "always";
      RestartSec = 10;
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
