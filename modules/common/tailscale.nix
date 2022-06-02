{ pkgs, ... }:

{
  services.tailscale.enable = true;
  systemd.services.tailscaled.after = [ "systemd-tmpfiles-setup.service" ];
  fileSystems."/var/lib/tailscale" = { device = "/persist/var/lib/tailscale"; options = [ "bind" ]; };
}
