{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.window-manager;

in {
  config = mkIf config.me.window-manager.enable {
    home-manager.users.${config.me.username}.programs.ghostty = {
      enable = false;
      enableZshIntegration = config.me.shell.zsh.enable;
      themes = {
        joshvanl = {
          palette = [
            "0=#000000"
            "1=#ff77AA"
            "2=#FF44CC"
            "3=#458588"
            "4=#8ec6cf"
            "5=#6eb6bf"
            "6=#FFBBCC"
            "7=#AAAAAA"
            "8=#000000"
            "9=#AA5050"
            "10=#FF44CC"
            "11=#458588"
            "12=#8ec6cf"
            "13=#6eb6bf"
            "14=#FFBBCC"
            "15=#AAAAAA"
          ];
          background = "#1c1c1c";
          foreground = "#f8f6f2";
          cursor-color = "#00557b";
          cursor-text = "#171717";
          selection-background = "#2a2d32";
          selection-foreground = "#b9bcba";
        };
      };
      settings = {
        cursor-style = "block";
        font-size = cfg.fontsize;
        font-family = "Menlo for Powerline";
        background-opacity = 0.97;
        window-decoration = "none";
        theme = "joshvanl";
        shell-integration-features = "no-cursor";
      };
    };
  };
}
