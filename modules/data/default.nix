{ lib, pkgs, config, ... }:
{
  imports = [
    ./zfs_uploader.nix
    ./nixcache.nix
  ];
}
