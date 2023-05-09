{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.networking.interfaces;

in {
  options.me.networking.interfaces = {
    intf = mkOption { };
    hostName = mkOption {
      type = types.str;
    };
  };

  config = {
    systemd.tmpfiles.rules = [
      "d /persist/etc/NetworkManager/system-connections 0755 ${config.me.base.username} wheel - -"
      "L+ /etc/NetworkManager/system-connections - - - - /persist/etc/NetworkManager/system-connections"
    ];

    networking = {
      networkmanager.enable = true;
      networkmanager.wifi.backend = "iwd";
      wireless.iwd.enable = true;
      wireless.userControlled.enable = false;
      hostName = cfg.hostName;
      hostId = "deadbeef";
      useDHCP  = false;
      nameservers = [
        "1.1.1.1"
        "8.8.8.8"
      ];
      interfaces = cfg.intf;
    };

    services.ntp.enable = true;

    home-manager.users.${config.me.base.username}.home.packages = with pkgs; [
      fast-cli
      wget
    ];
  };
}
