{ lib, pkgs, config, ... }:
{
  imports = [
    ./interfaces.nix
    ./ssh.nix
    ./tailscale.nix
    ./acme.nix
    ./nginx.nix
    ./podman.nix
    ./wireguard.nix
    ./networkmanager.nix
    ./dns.nix
    ./ncp.nix
  ];
}
