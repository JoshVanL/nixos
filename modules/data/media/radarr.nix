{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.data.media.radarr;

  mvDirSH = pkgs.writeShellApplication {
    name = "mvdir";
    text = ''
      rm "/var/lib/transmission/.config/transmission-daemon/torrents/''${TR_TORRENT_ID}.torrent"
      mv "$TR_TORRENT_DIR/$TR_TORRENT_NAME" ${config.me.data.media.radarr.videosDir}/.
    '';
  };

in {
  options.me.data.media.radarr = {
    enable = mkEnableOption "radarr";
    domain = mkOption {
      type = types.str;
    };
    videosDir = mkOption {
      type = types.str;
      default = "/keep/run/media/videos";
    };
    radarrDir = mkOption {
      type = types.str;
      default = "/keep/run/media/radarr";
    };
    transmissionDir = mkOption {
      type = types.str;
      default = "/keep/run/media/transmission";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {assertion = stringLength cfg.domain > 0; message = "Must provide a domain name";}
      {assertion = config.me.networking.acme.enable; message = "ACME must be enabled";}
    ];

    systemd.tmpfiles.rules = [
      "d ${cfg.transmissionDir} 0770 transmission transmission - -"
      "d ${cfg.videosDir} 0770 ${config.me.username} video - -"
    ];
    fileSystems = {
      "/var/lib/transmission" = { options = [ "bind" ]; device = cfg.transmissionDir; };
    };

    users.users.radarr.extraGroups = [ "video" "transmission" ];
    users.users.transmission.extraGroups = [ "video" ];

    services = {
      radarr = {
        enable = true;
        dataDir = cfg.radarrDir;
      };

      transmission = {
        enable = true;
        downloadDirPermissions = "770";
        settings = {
          script-torrent-done-enabled = true;
          script-torrent-done-filename = "${mvDirSH}/bin/mvdir";
        };
      };

      nginx = {
        enable = true;
        virtualHosts = {
          "${cfg.domain}" = {
            forceSSL = true;
            enableACME = true;
            acmeRoot = null;
            locations."/" = {
              proxyPass = "http://127.0.0.1:7878";
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
