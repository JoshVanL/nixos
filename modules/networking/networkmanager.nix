
{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.networking.networkmanager;

in {
  options.me.networking.networkmanager = { };

  config = {
    systemd.tmpfiles.rules = [
      "d /persist/etc/NetworkManager 0755 ${config.me.username} wheel - -"
      "d /persist/var/lib/iwd 0755 ${config.me.username} wheel - -"
    ];
    environment.etc."NetworkManager/system-connections".source = "/persist/etc/NetworkManager/system-connections";
    fileSystems."/var/lib/iwd" = { options = [ "bind" ]; device = "/persist/var/lib/iwd"; };

    systemd = {
      # Stop NetworkManager complaining on restart.
      services.NetworkManager-wait-online = {
        serviceConfig = {
          ExecStart = [ "" "${pkgs.networkmanager}/bin/nm-online -q" ];
          Restart = "on-failure";
          RestartSec = 1;
        };
        unitConfig.StartLimitIntervalSec = 0;
      };
    };

    users.users.${config.me.username}.extraGroups = [ "networkmanager" ];

    networking = {
      networkmanager.enable = true;
      networkmanager.wifi.backend = "iwd";
      wireless.iwd.enable = true;
      wireless.userControlled.enable = false;
    };
  };
}
