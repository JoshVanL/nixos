{ config, lib, pkgs, ... }:

{
  imports = [
    /keep/etc/nixos/modules/zfs_uploader
    /keep/etc/nixos/modules/common
  ]
  ++ lib.optional (builtins.pathExists ./sentinelone) (./sentinelone)
  ;
}
