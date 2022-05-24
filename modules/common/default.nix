{ config, lib, pkgs, modulesPath, ... }:

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
    ./docker.nix
    ./programs.nix
  ];

  zfs_uploader = {
    enable = true;
    logPath = "/keep/etc/zfs_uploader/zfs_uploader.log";
    configPath = "/persist/etc/zfs_uploader/config.cfg";
  };

  home-manager.users.josh = { pkgs, ... }: {
    programs.home-manager.enable = true;
  };
}
