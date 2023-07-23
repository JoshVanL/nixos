{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.networking.tailscale;

in {
  options.me.networking.tailscale = {
    enable = mkEnableOption "tailsacle";
    vpn = {
      enable = mkEnableOption "vpn";
      exitNode = mkOption {
        type = types.str;
        default = "";
        description = "The name of the exit node to use.";
      };
    };
    ingress = {
      enable = mkEnableOption "ingress";
      isExitNode = mkOption {
        type = types.bool;
        default = false;
        description = "Whether this node is an exit node (i.e. forwards traffic to the internet).";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {assertion = !cfg.vpn.enable || stringLength cfg.vpn.exitNode > 0; message = "You must specify an exit node if you want to use Tailscale as a VPN.";}
      {assertion = !cfg.vpn.enable || !cfg.ingress.enable; message = "You cannot use Tailscale as a VPN and an ingress node at the same time.";}
      {assertion = cfg.ingress.enable || !cfg.ingress.isExitNode; message = "You cannot be an exit node if you are not an ingress node.";}
    ];

    services.tailscale = {
      enable = true;
      # Don't enable IP forwarding by default if we are a server.
      useRoutingFeatures = if cfg.ingress.enable then "none" else "client";
    };

    fileSystems."/var/lib/tailscale" = { device = "/persist/var/lib/tailscale"; options = [ "bind" ]; };

    networking.firewall = mkIf cfg.ingress.enable {
      enable = true;
      trustedInterfaces = [ "tailscale0" ];
      # allow the Tailscale UDP port through the firewall
      allowedUDPPorts = [ config.services.tailscale.port ];
      # allow you to SSH in over the public internet
      allowedTCPPorts = optionals config.me.networking.ssh.ingress.enable [ 22 ];
      checkReversePath = mkIf (!cfg.ingress.enable) "loose";
    };

    boot.kernel.sysctl = mkIf cfg.ingress.isExitNode {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    systemd = {
      services = {
        tailscaled.after = [
          "systemd-tmpfiles-setup.service"
          "NetworkManager.service"
          "time-sync.target"
        ];

        tailscale-up = {
          description = "Start tailscale up";
          wantedBy = [ "default.target" ];
          after = [ "tailscaled.service" ];
          partOf = [ "tailscaled.service" ];
          serviceConfig = {
            Type = "simple";
            RestartSec = 3;
            Restart = "on-failure";
            RemainAfterExit = true;
            ExecStart = "${pkgs.tailscale}/bin/tailscale up --reset --accept-routes=true " + (
              if cfg.vpn.enable then "--exit-node ${cfg.vpn.exitNode} --accept-dns=true --exit-node-allow-lan-access=true"
              else if cfg.ingress.enable then "--advertise-exit-node=true --accept-dns=false"
              else ""
            );
            ExecStop = "${pkgs.tailscale}/bin/tailscale down";
          };
        };
      };
      user.tmpfiles.rules = [
        "d /persist/var/lib/tailscale 0700 root root - -"
      ];
    };

    home-manager.users.${config.me.username}.home.packages = with pkgs; [
      tailscale
    ];
  };
}
