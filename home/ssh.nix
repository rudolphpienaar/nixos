{ ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "*" = {
        serverAliveInterval = 60;
        extraOptions = {
          StrictHostKeyChecking = "no";
        };
      };

      jump = {
        hostname = "73.238.37.110";
        port = 7778;
        user = "rudolphpienaar";
      };

      pannotia = {
        hostname = "10.0.0.230";
        port = 22;
        user = "rudolph";
      };

      pannotia230 = {
        hostname = "10.0.0.230";
        user = "rudolph";
        proxyJump = "jump";
      };

      kenorland199 = {
        hostname = "10.0.0.199";
        user = "rudolph";
        proxyJump = "jump";
      };

      kenorland = {
        hostname = "192.168.86.20";
        port = 22;
        user = "rudolph";
      };

      mercury = {
        hostname = "192.168.86.27";
        port = 22;
        user = "rudolphpienaar";
      };

      pangea230 = {
        hostname = "pangea.tch.harvard.edu";
        user = "rudolph";
        proxyJump = "pannotia";
      };

      tabmux = {
        hostname = "192.168.86.80";
        port = 8022;
      };

      phomux = {
        hostname = "192.168.86.54";
        port = 8022;
      };

      droid = {
        hostname = "localhost";
        port = 9022;
        proxyJump = "tabmux";
      };

      chrome = {
        hostname = "10.0.0.243";
        user = "rudolphpienaar";
        port = 2222;
      };

      penguin = {
        hostname = "192.168.86.90";
        user = "rudolphpienaar";
        port = 2222;
      };
    };
  };
}
