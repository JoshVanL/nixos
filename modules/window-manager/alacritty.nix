{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.window-manager;

in {
  config = mkIf config.me.window-manager.enable {
    home-manager.users.${config.me.username}.programs.alacritty = {
      enable = true;
      settings = {
        env = {
          TERM = "xterm-256color";
        };
        general.live_config_reload = true;
        window = {
          decorations = "full";
          opacity = 0.97;
        };
        colors.draw_bold_text_with_bright_colors = true;
        font = {
          normal.family = "Menlo for Powerline";
          bold.family = "Menlo for Powerline";
          italic.family = "Menlo for Powerline";
          size = cfg.fontsize;
        };
        cursor = {
          style = {
            shape = "Block";
            blinking = "Always";
          };
          blink_interval = 500;
        };
        colors = {
          primary = {
            background = "#1c1c1c";
            foreground = "#f8f6f2";
          };

          cursor = {
            text = "0x000000";
            cursor = "#00557b";
          };

          normal = {
            black = "#000000";
            red = "#AA5050";
            green = "#00AA00";
            yellow = "#458588";
            blue = "#008fAA";
            magenta = "#6eb6bf";
            cyan = "#44BFBF";
            white = "#AAAAAA";
          };

          bright = {
            black = "#555555";
            red = "#ff77AA";
            green = "#FF44CC";
            yellow = "#FFFF55";
            blue = "#8ec6cf";
            magenta = "#FF88FF";
            cyan = "#FFBBCC";
            white = "#AAAAAA";
          };
        };

        keyboard.bindings = [
          {key="V";        mods="Control|Shift"; action = "Paste";}
          {key="C";        mods="Control|Shift"; action = "Copy";}
          {key="Q";        mods="Command";       action = "Quit";}
          {key="W";        mods="Command";       action = "Quit";}
          {key="Insert";   mods="Shift";         action = "PasteSelection";}
        ];

        mouse = {
          hide_when_typing = true;
          bindings = [
            {mouse="Middle"; action = "PasteSelection";}
          ];
        };
      };
    };
  };
}
