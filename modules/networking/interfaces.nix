{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.networking;

  myIPSH = pkgs.writeShellApplication {
    name = "myip";
    runtimeInputs = with pkgs; [ curl ];
    text = ''
      curl -L http://ipconfig.me
    '';
  };

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
      myIPSH
    ];
  };
}
