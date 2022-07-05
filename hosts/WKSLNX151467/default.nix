{ lib, pkgs, ... }:

{
  services = {
    sentinelone = {
      enable          = true;
      site_token_path = "/persist/etc/sentinelone/site_token";
    };

    kolide-launcher = {
      enable = true;
      deb_file = "zxkx_josh-van-leeuwen-e374f9_kolide-launcher.deb";
    };
  };

  systemd.tmpfiles.rules = [ "d  /keep/opt/sentinelone/model 0755 root root - -" ];
  fileSystems = {
    "/opt/sentinelone/model" = { options = [ "bind" ]; device = "/keep/opt/sentinelone/model";  };
  };
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    # SentinalOne Agent is not free software.
    "sentinelone"
    "kolide-launcher"
  ];
}
