{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.networking.tailscale;

in {
  options.me.networking.tailscale = {
    enable = mkEnableOption "tailsacle";

    ingress.enable = mkEnableOption "ingress";
  };

  config = mkIf cfg.enable {
    services.tailscale.enable = true;
    fileSystems."/var/lib/tailscale" = { device = "/persist/var/lib/tailscale"; options = [ "bind" ]; };

    networking.firewall = mkIf cfg.ingress.enable {
      enable = true;
      trustedInterfaces = [ "tailscale0" ];
      # allow the Tailscale UDP port through the firewall
      allowedUDPPorts = [ config.services.tailscale.port ];
      # allow you to SSH in over the public internet
      allowedTCPPorts = optionals config.me.networking.ssh.ingress.enable [ 22 ];
      checkReversePath = "loose";
    };

    systemd = {
      services.tailscaled.after = [ "systemd-tmpfiles-setup.service" ];
      user.tmpfiles.rules = [
        "d /persist/var/lib/tailscale 0700 root root - -"
      ];
    };

    home-manager.users.${config.me.username}.home.packages = with pkgs; [
      tailscale
    ];
  };
}
