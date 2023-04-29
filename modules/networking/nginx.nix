{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.networking.nginx;

in {
  options.me.networking.nginx = {};

  config = {
    services.nginx = {
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
      appendHttpConfig = ''
        resolver 8.8.8.8 ipv6=off;
      '';
    };
    systemd.services.nginx.after = [ "systemd-tmpfiles-setup.service" ];
  };
}
