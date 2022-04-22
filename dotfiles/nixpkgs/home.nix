{ config, pkgs, ... }:

{
  imports = [
    ./git.nix
    ./zsh.nix
    ./vim.nix
  ];

  home.username = "josh";
  home.homeDirectory = "/home/josh";

  programs.home-manager.enable = true;
}
