{ config, lib, pkgs, ... }:

{
  # Docker is good software.
  # ... Naaat.
  virtualisation.docker = {
    enable = true;
    storageDriver = "zfs";
  };
  # Don't enable docker unit by default.
  systemd.services.docker.wantedBy = lib.mkForce [];
}
