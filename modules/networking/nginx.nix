{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.networking.nginx;

in {
  options.me.networking.nginx = {};

  config = {
    services.nginx = {
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
      recommendedGzipSettings = true;
      #recommendedProxySettings = true;
      appendHttpConfig = ''
        resolver 8.8.8.8 ipv6=off;
        access_log off;

        proxy_buffering off;
        proxy_request_buffering off;
        proxy_connect_timeout   60s;
        proxy_send_timeout      60s;
        proxy_read_timeout      60s;
        proxy_http_version      1.1;

        aio threads;
        directio 4m;
      '';
    };
    systemd.services.nginx.after = [ "systemd-tmpfiles-setup.service" ];
  };
}
