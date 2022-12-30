{ config, lib, pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;
    storageDriver = "zfs";
  };
  systemd.services.docker.wantedBy = lib.mkForce [];
}
