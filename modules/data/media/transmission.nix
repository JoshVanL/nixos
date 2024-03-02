{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.data.media.transmission;

in {
  options.me.data.media.transmission = {
    enable = mkEnableOption "transmission";
    domain = mkOption {
      type = types.str;
    };
    dataDir = mkOption {
      type = types.str;
      default = "/keep/run/media/transmission";
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0770 transmission transmission - -"
    ];

    users.users.${config.me.username}.extraGroups = [ "transmission" ];

    containers.transmission = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "192.168.100.10";
      localAddress = "192.168.100.11";
      bindMounts = {
        "${cfg.dataDir}" = {
          hostPath = cfg.dataDir;
          isReadOnly = false;
        };
      };
      ephemeral = true;
      config = { pkgs, ... }: {
        fileSystems = {
          "/var/lib/transmission" = { options = [ "bind" ]; device = cfg.dataDir; };
        };
        services.transmission = {
          enable = true;
          downloadDirPermissions = "770";
          settings = {
            rpc-bind-address = "192.168.100.11";
            rpc-whitelist = "192.168.100.*";
            rpc-whitelist-enabled = true;
            rpc-username = "admin";
            rpc-password = "admin";
          };
        };
        systemd.services.transmission.serviceConfig = {
          RootDirectoryStartOnly = lib.mkForce false;
          RootDirectory = lib.mkForce "";
        };
        system.stateVersion = config.system.stateVersion;
        networking.firewall = {
          enable = true;
          allowedTCPPorts = [ 9091 ];
        };
      };
    };
  };
}
