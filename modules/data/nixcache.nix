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
    maxCacheSize = mkOption {
      type = types.str;
    };
    maxCacheAge = mkOption {
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d /keep/var/cache/nix 0755 ${config.me.base.username} wheel - -"
    ];

    # Config based from
    # https://github.com/nh2/nix-binary-cache-proxy/tree/b144bad7e95fc78ab50b2230df4920938899dab0
    services.nginx = {
      enable = true;
      appendHttpConfig = ''
        proxy_cache_path /keep/var/cache/nix levels=1:2 keys_zone=cachecache:100m max_size=${cfg.maxCacheSize} inactive=${cfg.maxCacheAge} use_temp_path=off;

        # Cache only success status codes; in particular we don't want to cache 404s.
        # See https://serverfault.com/a/690258/128321
        map $status $cache_header {
          200     "public";
          302     "public";
          default "no-cache";
        }
      '';

      virtualHosts = {
        ${cfg.domain} = {
          forceSSL = true;
          enableACME = true;
          acmeRoot = null;
          extraConfig = ''
            # Using a variable for the upstream endpoint to ensure that it is
            # resolved at runtime as opposed to once when the config file is loaded
            # and then cached forever (we don't want that):
            # see https://tenzer.dk/nginx-with-dynamic-upstreams/
            # This fixes errors like
            #   nginx: [emerg] host not found in upstream "upstream.example.com"
            # when the upstream host is not reachable for a short time when
            # nginx is started.
            resolver 8.8.8.8;
            set $upstream_endpoint http://cache.nixos.org;
          '';
          locations."/" = {
            root = "/var/public-nix-cache";
            extraConfig = ''
              add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
              expires max;
              add_header Cache-Control $cache_header always;
              # Ask the upstream server if a file isn't available locally
              error_page 404 = @fallback;
            '';
          };
          locations."@fallback" = {
            proxyPass = "$upstream_endpoint";
            extraConfig = ''
              proxy_cache cachecache;
              proxy_cache_valid  200 302  60m;
              expires max;
              add_header Cache-Control $cache_header always;
            '';
          };
          # We always want to copy cache.nixos.org's nix-cache-info file,
          # and ignore our own, because `nix-push` by default generates one
          # without `Priority` field, and thus that file by default has priority
          # 50 (compared to cache.nixos.org's `Priority: 40`), which will make
          # download clients prefer `cache.nixos.org` over our binary cache.
          locations."= /nix-cache-info" = {
            # Note: This is duplicated with the `@fallback` above,
            # would be nicer if we could redirect to the @fallback instead.
            proxyPass = "$upstream_endpoint";
            extraConfig = ''
              proxy_cache cachecache;
              proxy_cache_valid  200 302  60m;
              expires max;
              add_header Cache-Control $cache_header always;
            '';
          };
        };
      };
    };
  };
}
