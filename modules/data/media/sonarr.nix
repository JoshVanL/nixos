{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.data.media.sonarr;

in {
  options.me.data.media.sonarr = {
    enable = mkEnableOption "sonarr";
    domain = mkOption {
      type = types.str;
    };
    dataDir = mkOption {
      type = types.str;
      default = "/keep/run/media/sonarr";
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

    containers.sonarr = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "192.168.100.16";
      localAddress = "192.168.100.17";
      bindMounts = {
        "${cfg.dataDir}" = {
          hostPath = cfg.dataDir;
          isReadOnly = false;
        };
        "${cfg.videosDir}" = {
          hostPath = cfg.videosDir;
          isReadOnly = false;
        };
      };
      ephemeral = true;
      config = { ... }: {
        services.sonarr = {
          enable = true;
          dataDir = cfg.dataDir;
        };
        users.users.sonarr.extraGroups = [ "video" ];
        system.stateVersion = config.system.stateVersion;
        networking = {
          firewall.enable = true;
          firewall.allowedTCPPorts = [ 8989 ];
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
            proxyPass = "http://192.168.100.17:8989";
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
