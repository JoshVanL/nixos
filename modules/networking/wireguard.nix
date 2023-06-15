{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.me.networking.wireguard;

in {
  options.me.networking.wireguard = {
    enable = mkEnableOption "wireguard";

    addresses = mkOption {
      type = types.listOf types.str;
    };
    dns = mkOption {
      type = types.listOf types.str;
    };
    privateKeyFile = mkOption {
      type = types.path;
    };
    peer = {
      endpoint = mkOption {
        type = types.str;
      };
      publicKey = mkOption {
        type = types.str;
      };
    };
  };

  config = mkIf cfg.enable {
    networking = {
      nameservers = mkForce [];
      networkmanager.insertNameservers = mkForce (
        cfg.dns ++
        optionals config.me.networking.tailscale.enable [ "100.100.100.100" ]
      );
      wg-quick.interfaces = {
        wg0 = {
          address = cfg.addresses;
          privateKeyFile = cfg.privateKeyFile;
          peers = [
            {
              publicKey = cfg.peer.publicKey;
              allowedIPs = [ "0.0.0.0/0" ];
              endpoint = cfg.peer.endpoint;
            }
          ];
        };
      };
    };
  };
}
