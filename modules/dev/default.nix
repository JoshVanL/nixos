{ lib, pkgs, config, ... }:
{
  imports = [
    ./build.nix
    ./c.nix
    ./crypto.nix
    ./data.nix
    ./go.nix
    ./image.nix
    ./kube.nix
    ./python.nix
  ];
}
