{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.networking.dns;

in {
  options.me.networking.dns = { };

  config = {
    networking = {
      hostName = config.me.machineName;
      hostId = "deadbeef";
      useDHCP  = false;
      nameservers = [
        "1.1.1.1"
        "8.8.8.8"
      ];
    };

    # mDNS
    services.avahi.enable = true;
  };
}
