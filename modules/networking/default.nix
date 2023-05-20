{ lib, pkgs, config, ... }:
{
  imports = [
    ./interfaces.nix
    ./ssh.nix
    ./tailscale.nix
    ./acme.nix
    ./nginx.nix
    ./podman.nix
  ];
}
