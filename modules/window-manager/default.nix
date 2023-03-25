{ lib, pkgs, config, ... }:
with lib;

{
  imports = [
    ./window-manager.nix
    ./alacritty.nix
    ./browser.nix
    ./fonts.nix
    ./gtk.nix
    ./rofi.nix
  ];
}
