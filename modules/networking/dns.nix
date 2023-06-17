{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.networking.dns;

in {
  options.me.networking.dns = {
    hostname = mkOption {
      type = types.str;
    };
  };

  config = {
    networking = {
      hostName = cfg.hostname;
      hostId = "deadbeef";
      useDHCP  = false;
      nameservers = optionals (!config.me.networking.wireguard.enable) [
        "1.1.1.1"
        "8.8.8.8"
      ];
    };

    # mDNS
    services.avahi.enable = true;
  };
}
