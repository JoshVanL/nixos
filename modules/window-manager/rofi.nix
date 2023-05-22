{ lib, pkgs, config, ... }:
with lib;
let
  rofitheme = pkgs.fetchFromGitHub {
    owner = "bardisty";
    repo = "gruvbox-rofi";
    rev = "master";
    sha256 = "sha256-nAVNtibzVhv1wBcAo36jvHbsN7spFYjjm3IhcAeoM6M=";
  };

in {
  config = mkIf config.me.window-manager.enable {
    home-manager.users.${config.me.username}.home = {
      packages = with pkgs; [
        rofi
      ];

      file = {
        ".config/rofi/gruvbox-dark-soft.rasi".source = "${rofitheme}/gruvbox-dark-soft.rasi";
        ".config/rofi/config.rasi".text = ''
          configuration {
            modi: "drun,window";
            show-icons: true;
            icon-theme: "Paper";
            sidebar-mode: false;
            display-drun: "";
            font: "hack 50";
          }
          @theme "gruvbox-dark-soft"
          element-icon {
            size: 2.0ch;
          }
        '';
      };
    };
  };
}
