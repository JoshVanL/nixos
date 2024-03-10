{ lib
, pkgs
, config
, ...
}:

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
    assertions = [
      {assertion = !cfg.server.enable || config.me.networking.acme.enable; message = "ACME must be enabled when server enabled";}
    ];

    home-manager.users.${config.me.username}.home = {
      packages = with pkgs; [
        bitwarden-cli
      ];
    };

    systemd.tmpfiles.rules = [
      "d /persist/home/.config/Bitwarden 0755 ${config.me.username} wheel - -"
      "d /persist/home/.config/BitwardenCLI 0755 ${config.me.username} wheel - -"
      "L+ /home/${config.me.username}/.config/Bitwarden - - - - /persist/home/.config/Bitwarden"
      "L+ '/home/${config.me.username}/.config/Bitwarden CLI' - - - - /persist/home/.config/BitwardenCLI"
    ] ++ (optionals cfg.server.enable [
      "d /persist/var/lib/postgresql 0755 ${config.me.username} wheel - -"
      "d /persist/var/lib/bitwarden_rs 0755 vaultwarden vaultwarden - -"
    ]);

    containers.vaultwarden = mkIf cfg.server.enable {
      autoStart = cfg.server.enable;
      privateNetwork = true;
      hostAddress = "192.168.100.18";
      localAddress = "192.168.100.19";
      bindMounts = {
        "/var/lib/bitwarden_rs" = {
          hostPath = "/persist/var/lib/bitwarden_rs";
          isReadOnly = false;
        };
        "/var/lib/postgresql" = {
          hostPath = "/persist/var/lib/postgresql";
          isReadOnly = false;
        };
      };
      ephemeral = true;
      config = { ... }: {
        system.stateVersion = config.system.stateVersion;
        networking = {
          firewall.enable = true;
          firewall.allowedTCPPorts = [ rocketPort ];
        };
        services = {
          vaultwarden = {
            enable = true;
            dbBackend = "postgresql";
            config = {
              tz = "Europe/London";
              domain = "https://${cfg.server.domain}";
              signupsAllowed = false;
              invitationsAllowed = false;
              rocketAddress = "0.0.0.0";
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
               ensureDBOwnership = true;
             }
            ];
          };
          postgresqlBackup = {
            enable = true;
            databases = [ "vaultwarden" ];
          };
        };
      };
    };

    services = mkIf cfg.server.enable {
      nginx = {
        enable = true;
        virtualHosts = {
          ${cfg.server.domain} = {
            forceSSL = true;
            enableACME = true;
            acmeRoot = null;
            locations."/" = {
              proxyPass = "http://192.168.100.19:${toString rocketPort}";
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
