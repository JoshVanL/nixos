{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.data.media.jackett;

in {
  options.me.data.media.jackett = {
    enable = mkEnableOption "jackett";
    domain = mkOption {
      type = types.str;
    };
    dataDir = mkOption {
      type = types.str;
      default = "/keep/run/media/jackett";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {assertion = stringLength cfg.domain > 0; message = "Must provide a domain name";}
    ];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 jackett jackett - -"
    ];
    fileSystems = {
      "/var/lib/jackett" = { options = [ "bind" ]; device = cfg.dataDir; };
    };

    services = {
      jackett = {
        enable = true;
      };

      nginx = {
        enable = true;
        virtualHosts = {
          "${cfg.domain}" = {
            forceSSL = true;
            enableACME = true;
            acmeRoot = null;
            locations."/" = {
              proxyPass = "http://127.0.0.1:9117";
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
  };
}
