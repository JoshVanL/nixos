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
    isExitNode = mkOption {
      type = types.bool;
      default = false;
      description = "Whether this node is an exit node (i.e. forwards traffic to the internet).";
    };
  };

  config = mkIf cfg.enable {
    systemd.services = {
      tailscaled.after = [ "wg-quick-wg0.service" ];
      wg-quick-wg0.after = [ "time-sync.target" ];
    };

    boot.kernel.sysctl = mkIf cfg.isExitNode {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    networking = {
      networkmanager.insertNameservers = cfg.dns;
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
