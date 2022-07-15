{ lib, pkgs, ... }:

{
  services = {
    sentinelone = {
      enable          = true;
      site_token_path = "/persist/etc/sentinelone/site_token";
    };

    kolide-launcher = {
      enable = true;
      deb_file = "zxkx_josh-van-leeuwen-ff00b2_kolide-launcher.deb";
    };
  };

  systemd.tmpfiles.rules = [
    "d  /keep/opt/sentinelone/model 0755 root root - -"
    "d  /keep/var/kolide-k2         0755 root root - -"
  ];
  fileSystems = {
    "/opt/sentinelone/model" = { options = [ "bind" ]; device = "/keep/opt/sentinelone/model";  };
    "/var/kolide-k2"         = { options = [ "bind" ]; device = "/keep/var/kolide-k2";  };
  };
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    # SentinalOne Agent and the Kolide Launcher is not free software.
    "sentinelone"
    "kolide-launcher"
  ];
}
