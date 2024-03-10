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
      {assertion = config.me.networking.acme.enable; message = "ACME must be enabled";}
    ];

    users.users.${config.me.username}.extraGroups = [ "jackett" ];
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 jackett jackett - -"
    ];

    containers.jackett = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "192.168.100.12";
      localAddress = "192.168.100.13";
      bindMounts = { "/var/lib/jackett" = {
        hostPath = cfg.dataDir;
        isReadOnly = false;
      }; };
      ephemeral = true;
      config = { ... }: {
        services.jackett.enable = true;
        system.stateVersion = config.system.stateVersion;
        networking = {
          firewall.enable = true;
          firewall.allowedTCPPorts = [ 9117 ];
        };
        systemd.services.flareresolverr = let
          flaresolverr = config.nur.repos.xddxdd.flaresolverr;
        in {
          enable = true;
          unitConfig.Type = "simple";
          serviceConfig.ExecStart = "${flaresolverr}/bin/flaresolverr";
          wantedBy = [ "multi-user.target" ];
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
            proxyPass = "http://192.168.100.13:9117";
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
