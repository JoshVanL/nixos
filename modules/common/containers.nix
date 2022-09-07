{ config, lib, pkgs, ... }:

{
  #virtualisation.podman = {
  virtualisation.docker = {
    enable = true;
    #extraPackages = [ pkgs.zfs ];
    storageDriver = "zfs";
  };
  #systemd.services.podman.wantedBy = lib.mkForce [];
  systemd.services.docker.wantedBy = lib.mkForce [];
}
