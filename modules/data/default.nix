{ lib, pkgs, config, ... }:
{
  imports = [
    ./zfs_uploader.nix
  ];
}
