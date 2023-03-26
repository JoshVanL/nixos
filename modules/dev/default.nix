{ lib, pkgs, config, ... }:
{
  imports = [
    ./c.nix
    ./crypto.nix
    ./data.nix
    ./go.nix
    ./image.nix
    ./kube.nix
    ./python.nix
  ];
}
