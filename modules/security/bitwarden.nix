{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.security.bitwarden;

  rocketPort = 8222;

in {
  options.me.security.bitwarden = {
    enable = mkEnableOption "bitwarden";

    server = {
      enable = mkEnableOption "bitwarden server";
      domain = mkOption {
        type = types.str;
      };
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.me.username}.home = {
      packages = with pkgs; [
        bitwarden-cli
      ];
    };

    systemd.tmpfiles.rules = [
      "d /persist/home/.config/Bitwarden 0755 ${config.me.username} wheel - -"
      "d '/persist/home/.config/Bitwarden\ CLI' 0755 ${config.me.username} wheel - -"
      "L+ /home/${config.me.username}/.config/Bitwarden - - - - /persist/home/.config/Bitwarden"
      "L+ '/home/${config.me.username}/.config/Bitwarden\ CLI' - - - - '/persist/home/.config/Bitwarden\ CLI'"
    ] ++ (optionals cfg.server.enable [
      "d /persist/var/lib/postgresql 0755 ${config.me.username} wheel - -"
      "d /persist/var/lib/bitwarden_rs 0755 vaultwarden vaultwarden - -"
    ]);

    services = mkIf cfg.server.enable {
      vaultwarden = {
        enable = true;
        dbBackend = "postgresql";
        config = {
          tz = "Europe/London";
          domain = "https://${cfg.server.domain}";
          signupsAllowed = false;
          invitationsAllowed = false;
          rocketPort = rocketPort;
          databaseUrl = "postgresql://vaultwarden@%2Frun%2Fpostgresql/vaultwarden";
          enableDbWal = "false";
        };
      };
      postgresql = {
        enable = true;
        package        = pkgs.postgresql_14;
        authentication = lib.mkForce ''
          # TYPE  DATABASE        USER            ADDRESS                 METHOD
          local   all             all                                     trust
          host    all             all             127.0.0.1/32            trust
          host    all             all             ::1/128                 trust
        '';
        initialScript = pkgs.writeText "backend-initScript" ''
          CREATE ROLE vaultwarden WITH LOGIN PASSWORD 'vaultwarden' CREATEDB;
          CREATE DATABASE vaultwarden;
          GRANT ALL PRIVILEGES ON DATABASE vaultwarden TO vaultwarden;
        '';
        ensureDatabases = ["vaultwarden"];
        ensureUsers = [
         {
           name = "vaultwarden";
           ensurePermissions = {
             "DATABASE vaultwarden" = "ALL PRIVILEGES";
           };
         }
        ];
      };
      postgresqlBackup = {
        enable = true;
        databases = [ "vaultwarden" ];
      };
      nginx = {
        enable = true;
        virtualHosts = {
          ${cfg.server.domain} = {
            forceSSL = true;
            enableACME = true;
            acmeRoot = null;
            locations."/" = {
              proxyPass = "http://127.0.0.1:${toString rocketPort}";
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

    systemd.services = mkIf cfg.server.enable {
      postgresql.after = [ "systemd-tmpfiles-setup.service" ];
      vaultwarden = {
        wants = [ "nginx.service" ];
        after = ["systemd-tmpfiles-setup.service"  "nginx.service" ];
        bindsTo = [ "nginx.service" ];
      };
    };
    fileSystems = mkIf cfg.server.enable {
      "/var/lib/postgresql" = { options = [ "bind" ]; device = "/persist/var/lib/postgresql"; };
      "/var/lib/bitwarden_rs" = { options = [ "bind" ]; device = "/persist/var/lib/bitwarden_rs"; };
    };
  };
}
