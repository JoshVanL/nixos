{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.data.nixcache;

in {
  options.me.data.nixcache = {
    enable = mkEnableOption "nixcache";
    domain = mkOption {
      type = types.str;
    };
    secretKeyFile = mkOption {
      type = types.path;
    };
    cacheDir = mkOption {
      type = types.str;
      default = "/keep/var/run/nginx/cache/nix";
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
      "/run/nginx/cache/nix" = { options = [ "bind" ]; device = "${cfg.cacheDir}"; };
    };

    services.nginx = {
      enable = true;
      appendHttpConfig = ''
        proxy_cache_path /run/nginx/cache/nix levels=1:2 keys_zone=cache_zone:50m max_size=${cfg.maxCacheSize} inactive=${cfg.maxCacheAge};
      '';

      virtualHosts."${cfg.domain}" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = ''
          proxy_cache cache_zone;
          proxy_cache_valid 200 ${cfg.maxCacheAge};
          proxy_cache_use_stale error timeout invalid_header updating http_500 http_502 http_504 http_403 http_404 http_429;
          proxy_ignore_headers X-Accel-Expires Expires Cache-Control Set-Cookie Vary;
          proxy_cache_lock on;
          proxy_ssl_server_name on;
          proxy_ssl_verify on;
          proxy_ssl_trusted_certificate /etc/ssl/certs/ca-certificates.crt;
          set $upstream_endpoint https://cache.nixos.org;
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

        locations."/nix-cache-info" = {
          extraConfig = ''
            return 200 "StoreDir: /nix/store\nWantMassQuery: 1\nPriority: 41\n";
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
