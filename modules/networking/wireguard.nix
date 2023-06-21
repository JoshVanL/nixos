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
    systemd.services = {
      tailscaled.after = [ "wg-quick-wg0.service" ];
      wg-quick-wg0.after = [ "time-sync.target" ];
    };

    networking = {
      nameservers = mkForce [];
      networkmanager.insertNameservers = cfg.dns;
      wg-quick.interfaces = {
        wg0 = {
          address = cfg.addresses;
          privateKeyFile = cfg.privateKeyFile;
          dns = cfg.dns;
          postUp = mkIf config.me.networking.tailscale.enable [
            "${pkgs.iproute2}/bin/ip rule add preference 5200 from all lookup 52"
          ];
          postDown = mkIf config.me.networking.tailscale.enable [
            "${pkgs.iproute2}/bin/ip rule delete preference 5200"
          ];
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
