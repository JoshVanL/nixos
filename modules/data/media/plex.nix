{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.data.media.plex;

in {
  options.me.data.media.plex = {
    enable = mkEnableOption "plex";
    domain = mkOption {
      type = types.str;
    };
    plexDir = mkOption {
      type = types.str;
      default = "/keep/run/media/plex";
    };
    videosDir = mkOption {
      type = types.str;
      default = "/keep/run/media/videos";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {assertion = stringLength cfg.domain > 0; message = "Must provide a domain name";}
      {assertion = config.me.networking.acme.enable; message = "ACME must be enabled";}
    ];

    users.users.${config.me.username}.extraGroups = [ "video" ];

    systemd.tmpfiles.rules = [
      "d ${cfg.videosDir} 0770 ${config.me.username} video - -"
      "d ${cfg.plexDir} 0755 plex plex - -"
    ];
    containers.plex = {
      autoStart = true;
      bindMounts = {
        "${cfg.plexDir}" = {
          hostPath = cfg.plexDir;
          isReadOnly = false;
        };
        "${cfg.videosDir}" = {
          hostPath = cfg.videosDir;
          isReadOnly = false;
        };
      };
      ephemeral = true;
      config = { pkgs, ... }: {
        nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
          "plexmediaserver"
        ];
        fileSystems = {
          "/var/lib/plex" = { options = [ "bind" ]; device = cfg.plexDir; };
        };
        services.plex = {
          enable = true;
          openFirewall = true;
        };
        system.stateVersion = config.system.stateVersion;
        users.users.plex.extraGroups = [ "video" ];
        services.resolved.enable = true;
        networking = {
          useHostResolvConf = lib.mkForce false;
          firewall = {
            enable = true;
            allowedTCPPorts = [ 32400 ];
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 443 ];
    services.nginx = {
      enable = true;
      virtualHosts = {
        "${cfg.domain}" = {
          forceSSL = true;
          http2 = true;
          enableACME = true;
          acmeRoot = null;
          locations."/" = {
            proxyPass = "http://127.0.0.1:32400";
            proxyWebsockets = true;
          };
          extraConfig = ''
            send_timeout 100m;
            ssl_stapling on;
            ssl_stapling_verify on;

            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Host $server_addr;
            proxy_set_header Referer $server_addr;
            proxy_set_header Origin $server_addr;

            gzip on;
            gzip_vary on;
            gzip_min_length 1000;
            gzip_proxied any;
            gzip_types text/plain text/css text/xml application/xml text/javascript application/x-javascript image/svg+xml;
            gzip_disable "MSIE [1-6]\.";

            client_max_body_size 100M;

            proxy_set_header X-Plex-Client-Identifier $http_x_plex_client_identifier;
            proxy_set_header X-Plex-Device $http_x_plex_device;
            proxy_set_header X-Plex-Device-Name $http_x_plex_device_name;
            proxy_set_header X-Plex-Platform $http_x_plex_platform;
            proxy_set_header X-Plex-Platform-Version $http_x_plex_platform_version;
            proxy_set_header X-Plex-Product $http_x_plex_product;
            proxy_set_header X-Plex-Token $http_x_plex_token;
            proxy_set_header X-Plex-Version $http_x_plex_version;
            proxy_set_header X-Plex-Nocache $http_x_plex_nocache;
            proxy_set_header X-Plex-Provides $http_x_plex_provides;
            proxy_set_header X-Plex-Device-Vendor $http_x_plex_device_vendor;
            proxy_set_header X-Plex-Model $http_x_plex_model;

            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";

            proxy_buffering off;
          '';
        };
      };
    };
  };
}
