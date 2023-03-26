{ lib, pkgs, config, ... }:
{
  imports = [
    ./interfaces.nix
    ./ssh.nix
    ./tailscale.nix
  ];
}
