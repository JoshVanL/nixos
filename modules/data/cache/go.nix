{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.data.cache.go;

  goproxySH = pkgs.writeShellApplication {
    name = "goproxy.sh";
    runtimeInputs = with pkgs; [ goproxy go ];
    text = ''
      goproxy -insecure -cacher-dir ${cfg.cacheDir} -address localhost:8081
    '';
  };

in {
  options.me.data.cache.go = {
    enable = mkEnableOption "gocache";
    domain = mkOption {
      type = types.str;
    };
    cacheDir = mkOption {
      type = types.str;
      default = "/keep/var/run/nginx/cache/go";
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.cacheDir} 0755 ${config.me.base.username} wheel -"
    ];

    fileSystems = {
      "/run/nginx/cache/go" = { options = [ "bind" ]; device = "${cfg.cacheDir}"; };
    };

    systemd.services.goproxy = {
      enable = true;
      description = "Go Proxy";
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        User = "root";
        Group = "root";
        WorkingDirectory = "/tmp";
        ExecStart = "${goproxySH}/bin/goproxy.sh";
        Restart = "on-failure";
      };
      wantedBy = [ "default.target" ];
    };
    services.nginx = {
      enable = true;
      virtualHosts = {
        "${cfg.domain}" = {
          locations."/".extraConfig = ''
            proxy_pass http://localhost:8081;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          '';
        };
      };
    };
  };
}
