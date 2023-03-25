{ lib, pkgs, config, ... }:
{
  imports = [
    ./c.nix
    ./go.nix
    ./python.nix
    ./kube.nix
  ];
}
