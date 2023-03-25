{ lib, pkgs, config, ... }:
with lib;

{
  imports = [
    ./git.nix
    ./google.nix
    ./neovim.nix
    ./podman.nix
    ./zsh.nix
  ];
}
