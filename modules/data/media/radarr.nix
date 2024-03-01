{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.data.media.radarr;

in {
  options.me.data.media.radarr = {
    enable = mkEnableOption "radarr";
    domain = mkOption {
      type = types.str;
    };
    radarrDir = mkOption {
      type = types.str;
      default = "/keep/run/media/radarr";
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

    systemd.tmpfiles.rules = [
      "d ${cfg.videosDir} 0770 ${config.me.username} video - -"
    ];

    users.users.${config.me.username}.extraGroups = [ "video" ];

    containers.radarr = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "192.168.100.14";
      localAddress = "192.168.100.15";
      bindMounts = {
        "${cfg.radarrDir}" = {
          hostPath = cfg.radarrDir;
          isReadOnly = false;
        };
        "${cfg.videosDir}" = {
          hostPath = cfg.videosDir;
          isReadOnly = false;
        };
      };
      ephemeral = true;
      config = { pkgs, ... }: {
        services.radarr = {
          enable = true;
          dataDir = cfg.radarrDir;
        };
        system.stateVersion = config.system.stateVersion;
        users.users.radarr.extraGroups = [ "video" ];
        networking = {
          firewall.enable = true;
          firewall.allowedTCPPorts = [ 7878 ];
        };
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts = {
        "${cfg.domain}" = {
          forceSSL = true;
          enableACME = true;
          acmeRoot = null;
          locations."/" = {
            proxyPass = "http://192.168.100.15:7878";
            proxyWebsockets = true;
          };
          extraConfig = ''
            proxy_read_timeout 90;
            add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
            add_header X-Content-Type-Options nosniff;
            add_header X-XSS-Protection "1; mode=block";
            add_header X-Frame-Options SAMEORIGIN;
          '';
        };
      };
    };
  };
}
