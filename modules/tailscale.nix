{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.services.josh.tailscale;
in {
  options.services.josh.tailscale = {
    enable = mkEnableOption "tailsacle";
  };

  config = mkIf cfg.enable {
    services.tailscale.enable = true;
    systemd.services.tailscaled.after = [ "systemd-tmpfiles-setup.service" ];
    fileSystems."/var/lib/tailscale" = { device = "/persist/var/lib/tailscale"; options = [ "bind" ]; };
    networking.firewall.checkReversePath = "loose";
    environment.systemPackages = [ pkgs.tailscale ];
  };
}
