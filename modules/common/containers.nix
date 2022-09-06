{ config, lib, pkgs, ... }:

{
  virtualisation.podman = {
    enable = true;
    extraPackages = [ pkgs.zfs ];
  };
  systemd.services.podman.wantedBy = lib.mkForce [];
}
