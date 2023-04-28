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
  };

  config = mkIf cfg.enable {
    services.nix-serve = {
      enable = true;
      secretKeyFile = cfg.secretKeyFile;
    };
    services.nginx = {
      enable = true;
      virtualHosts = {
        ${cfg.domain} = {
          serverAliases = [ "nixcache" ];
          forceSSL = true;
          enableACME = true;
          acmeRoot = null;
          locations."/".extraConfig = ''
            proxy_pass http://localhost:${toString config.services.nix-serve.port};
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
          '';
        };
      };
    };
  };
}
