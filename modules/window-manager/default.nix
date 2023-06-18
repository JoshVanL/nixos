{ lib, pkgs, config, ... }:
{
  imports = [
    ./x.nix
    ./alacritty.nix
    ./browser.nix
    ./fonts.nix
    ./gtk.nix
    ./rofi.nix
  ];
}
