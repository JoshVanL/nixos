{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.networking.tailscale;

in {
  options.me.networking.tailscale = {
    enable = mkEnableOption "tailsacle";
  };

  config = mkIf cfg.enable {
    services.tailscale.enable = true;
    fileSystems."/var/lib/tailscale" = { device = "/persist/var/lib/tailscale"; options = [ "bind" ]; };
    networking.firewall.checkReversePath = "loose";

    systemd = {
      services.tailscaled.after = [ "systemd-tmpfiles-setup.service" ];
      user.tmpfiles.rules = [
        "d /persist/var/lib/tailscale 0755 ${config.me.username} wheel - -"
      ];
    };

    home-manager.users.${config.me.username}.home.packages = with pkgs; [
      tailscale
    ];
  };
}
