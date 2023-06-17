{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.networking.interfaces;

  myIPSH = pkgs.writeShellApplication {
    name = "myip";
    runtimeInputs = with pkgs; [ curl ];
    text = ''
      curl -L http://ipconfig.me
    '';
  };

in {
  options.me.networking.interfaces = {
    intf = mkOption { };
    hostName = mkOption {
      type = types.str;
    };
  };

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

    networking = {
      networkmanager.enable = true;
      networkmanager.wifi.backend = "iwd";
      wireless.iwd.enable = true;
      wireless.userControlled.enable = false;
      hostName = cfg.hostName;
      hostId = "deadbeef";
      useDHCP  = false;
      nameservers = optionals (!config.me.networking.wireguard.enable) [
        "1.1.1.1"
        "8.8.8.8"
      ];
      interfaces = cfg.intf;
    };

    # mDNS
    services.avahi.enable = true;
    services.timesyncd.enable = mkForce true;
    systemd.additionalUpstreamSystemUnits = [ "systemd-time-wait-sync.service" ];

    home-manager.users.${config.me.username}.home.packages = with pkgs; [
      fast-cli
      wget
      myIPSH
    ];
  };
}
