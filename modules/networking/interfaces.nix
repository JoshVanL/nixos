{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.networking;

in {
  options.me.networking = {
    interfaces = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of network interfaces to enable with DHCP";
    };
  };

  config = {
    networking.interfaces = listToAttrs (map (iface:
      nameValuePair iface { useDHCP = true; }
    ) cfg.interfaces);
    home-manager.users.${config.me.username}.home.packages = with pkgs; [
      fast-cli
      wget
      myip
    ];
  };
}
