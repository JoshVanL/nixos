{ config, lib, pkgs, ... }:

{
  imports = [
    ./zfs_uploader
    ./common
  ]
  ++ lib.optional (builtins.pathExists ./nixpkgs-internal) (./nixpkgs-internal)
  ;
}
