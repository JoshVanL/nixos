{ lib, pkgs, config, ... }:
{
  imports = [
    ./radarr.nix
    ./jackett.nix
    ./plex.nix
  ];
}
