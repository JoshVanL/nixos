{ pkgs, ... }:

let
  home-manager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/master.tar.gz";
  };
in {
  imports = [
    "${home-manager}/nixos"
    ./git.nix
    ./zsh.nix
    ./vim.nix
    ./alacritty.nix
    ./window-manager.nix
   ];

  home-manager.users.josh = { pkgs, ... }: {
    programs.home-manager.enable = true;
    home.username = "josh";
    home.homeDirectory = "/home/josh";
  };
}
