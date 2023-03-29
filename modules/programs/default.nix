{ lib, pkgs, config, ... }:
with lib;

{
  imports = [
    ./git.nix
    ./neovim.nix
    ./podman.nix
    ./zsh.nix
  ];
}
