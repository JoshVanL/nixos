{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.data.gocache;

in {
  options.me.data.gocache = {
    enable = mkEnableOption "gocache";
    domain = mkOption {
      type = types.str;
    };
    cacheDir = mkOption {
      type = types.str;
      default = "/keep/var/run/nginx/cache/go";
    };
    maxCacheSize = mkOption {
      type = types.str;
    };
    maxCacheAge = mkOption {
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.cacheDir} 0755 nginx nginx - -"
    ];

    fileSystems = {
      "/run/nginx/cache/go" = { options = [ "bind" ]; device = "${cfg.cacheDir}"; };
    };

    services.nginx = {
      enable = true;
      appendHttpConfig = ''
        proxy_cache_path /run/nginx/cache/go levels=1:2 keys_zone=go_cache_zone:50m max_size=${cfg.maxCacheSize} inactive=${cfg.maxCacheAge};
      '';

      virtualHosts."${cfg.domain}" = {
        forceSSL = true;
        enableACME = true;
        acmeRoot = null;
        extraConfig = ''
          proxy_cache go_cache_zone;
          proxy_cache_valid 200 ${cfg.maxCacheAge};
          proxy_cache_use_stale error timeout invalid_header updating http_500 http_502 http_504 http_403 http_404 http_429;
          proxy_ignore_headers X-Accel-Expires Expires Cache-Control Set-Cookie Vary;
          proxy_ssl_server_name on;
          proxy_ssl_verify on;
          proxy_ssl_trusted_certificate /etc/ssl/certs/ca-certificates.crt;
          set $upstream_endpoint https://proxy.golang.org;
        '';
        locations."/" = {
          proxyPass = "$upstream_endpoint";
          extraConfig = ''
            proxy_send_timeout 300ms;
            proxy_connect_timeout 300ms;

            error_page 502 504 =404 @fallback;

            proxy_set_header Host $proxy_host;
          '';
        };

        locations."@fallback" = {
          extraConfig = ''
            return 200 "404";
          '';
        };
      };
    };
  };
}
