{ config, lib, pkgs, ... }:

let
  home-manager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/master.tar.gz";
  };
in {
  imports = [
    "${home-manager}/nixos"

    ./yubikey.nix
    ./git.nix
    ./zsh.nix
    ./vim.nix
    ./alacritty.nix
    ./wayland.nix
    ./window-manager.nix
    ./links.nix
    ./gtk.nix
    ./fonts.nix
    ./backup.nix
    ./docker.nix
    ./programs.nix
   ];

  home-manager.users.josh = { pkgs, ... }: {
    programs.home-manager.enable = true;
  };
}
