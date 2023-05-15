{ lib, pkgs, config, ... }:
with lib;

{
  imports = [
    ./alias.nix
    ./git.nix
    ./neovim.nix
    ./podman.nix
    ./zsh.nix
  ];
}
