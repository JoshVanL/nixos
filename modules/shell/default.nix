{ lib, pkgs, config, ... }:
with lib;

{
  imports = [
    ./neovim.nix
    ./zsh.nix
  ];
}
