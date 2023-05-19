{ lib, pkgs, config, ... }:
{
  imports = [
    ./go.nix
    ./nix.nix
    ./machine.nix
  ];
}
