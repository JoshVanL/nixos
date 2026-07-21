{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.window-manager;

in {
  config = mkIf config.me.window-manager.enable {
    home-manager.users.${config.me.username}.programs.ghostty = {
      enable = true;
      enableZshIntegration = config.me.shell.zsh.enable;
      themes = {
        joshvanl = {
          palette = [
            # normal (Alacritty colors.normal)
            "0=#000000"
            "1=#AA5050"
            "2=#00AA00"
            "3=#458588"
            "4=#008fAA"
            "5=#6eb6bf"
            "6=#44BFBF"
            "7=#AAAAAA"
            # bright (Alacritty colors.bright)
            "8=#555555"
            "9=#ff77AA"
            "10=#FF44CC"
            "11=#FFFF55"
            "12=#8ec6cf"
            "13=#FF88FF"
            "14=#FFBBCC"
            "15=#AAAAAA"
          ];
          background = "#1c1c1c";
          foreground = "#f8f6f2";
          cursor-color = "#00557b";
          cursor-text = "#000000";
          selection-background = "#2a2d32";
          selection-foreground = "#b9bcba";
        };
      };
      settings = {
        cursor-style = "block";
        cursor-style-blink = true;
        font-size = cfg.fontsize;
        font-family = "Menlo for Powerline";
        background-opacity = 0.97;
        window-decoration = true;
        theme = "joshvanl";
        bold-is-bright = true;
        mouse-hide-while-typing = true;
        term = "xterm-256color";
        shell-integration-features = "no-cursor";
      };
    };
  };
}
