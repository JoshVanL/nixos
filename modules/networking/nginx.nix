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
        access_log off;
        sendfile_max_chunk 5m;
        proxy_buffering off;
        proxy_request_buffering off;
      '';
    };
    systemd.services.nginx.after = [ "systemd-tmpfiles-setup.service" ];
  };
}
