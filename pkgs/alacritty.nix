{ pkgs, ... }:

let
  home-manager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/master.tar.gz";
  };
in {
  home-manager.users.josh = { pkgs, ... }: {
    programs.alacritty = {
      enable = true;
      settings = {
        env = {
          TERM = "xterm-256color";
        };
        window = {
          decorations = "full";
          opacity = 0.97;
        };
        tabspaces = 4;
        draw_bold_text_with_bright_colors = true;
        font = {
          normal.family = "Menlo for Powerline";
          bold.family = "Menlo for Powerline";
          italic.family = "Menlo for Powerline";
          size = 9.7;
          scale_with_dpi = false;
        };
        custom_cursor_colors = false;
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

        key_bindings = [
          {key="V";        mods="Control|Shift"; action = "Paste";}
          {key="C";        mods="Control|Shift"; action = "Copy";}
          {key="Q";        mods="Command";       action = "Quit";}
          {key="W";        mods="Command";       action = "Quit";}
          {key="Insert";   mods="Shift";         action = "PasteSelection";}
          {key="Home";                           chars = "\\x1bOH";   mode = "AppCursor";}
          {key="Home";                           chars = "\\x1b[H";   mode = "~AppCursor";}
          {key="End";                            chars = "\\x1bOF";   mode = "AppCursor";}
          {key="End";                            chars = "\\x1b[F";   mode = "~AppCursor";}
          {key="PageUp";   mods="Shift";         chars = "\\x1b[5;2~";}
          {key="PageUp";   mods="Control";       chars = "\\x1b[5;5~";}
          {key="PageUp";                         chars = "\\x1b[5~";}
          {key="PageDown"; mods="Shift";         chars = "\\x1b[6;2~";}
          {key="PageDown"; mods="Control";       chars = "\\x1b[6;5~";}
          {key="PageDown";                       chars = "\\x1b[6~";}
          {key="Left";     mods="Shift";         chars = "\\x1b[1;2D";}
          {key="Left";     mods="Control";       chars = "\\x1b[1;5D";}
          {key="Left";     mods="Alt";           chars = "\\x1b[1;3D";}
          {key="Left";                           chars = "\\x1b[D"; mode = "~AppCursor";}
          {key="Left";                           chars = "\\x1bOD"; mode = "AppCursor";}
          {key="Right";    mods="Shift";         chars = "\\x1b[1;2C";}
          {key="Right";    mods="Control";       chars = "\\x1b[1;5C";}
          {key="Right";    mods="Alt";           chars = "\\x1b[1;3C";}
          {key="Right";                          chars = "\\x1b[C"; mode = "~AppCursor";}
          {key="Right";                          chars = "\\x1bOC"; mode = "AppCursor";}
          {key="Up";       mods="Shift";         chars = "\\x1b[1;2A";}
          {key="Up";       mods="Control";       chars = "\\x1b[1;5A";}
          {key="Up";       mods="Alt";           chars = "\\x1b[1;3A";}
          {key="Up";                             chars = "\\x1b[A";mode = "~AppCursor";}
          {key="Up";                             chars = "\\x1bOA";mode = "AppCursor";}
          {key="Down";     mods="Shift";         chars = "\\x1b[1;2B";}
          {key="Down";     mods="Control";       chars = "\\x1b[1;5B";}
          {key="Down";     mods="Alt";           chars = "\\x1b[1;3B";}
          {key="Down";                           chars = "\\x1b[B"; mode = "~AppCursor";}
          {key="Down";                           chars = "\\x1bOB"; mode = "AppCursor";}
          {key="Tab";      mods="Shift";         chars = "\\x1b[Z";}
          {key="F1";                             chars = "\\x1bOP";}
          {key="F2";                             chars = "\\x1bOQ";}
          {key="F3";                             chars = "\\x1bOR";}
          {key="F4";                             chars = "\\x1bOS";}
          {key="F5";                             chars = "\\x1b[15~";}
          {key="F6";                             chars = "\\x1b[17~";}
          {key="F7";                             chars = "\\x1b[18~";}
          {key="F8";                             chars = "\\x1b[19~";}
          {key="F9";                             chars = "\\x1b[20~";}
          {key="F10";                            chars = "\\x1b[21~";}
          {key="F11";                            chars = "\\x1b[23~";}
          {key="F12";                            chars = "\\x1b[24~";}
          {key="Back";                           chars = "\\x7f";}
          {key="Back";     mods="Alt";           chars = "\\x1b\\x7f";}
          {key="Insert";                         chars = "\\x1b[2~";}
          {key="Delete";                         chars = "\\x1b[3~";}
        ];

        mouse_bindings = [
          {mouse="Middle"; action = "PasteSelection";}
        ];

        mouse = {
          double_click = {threshold = 300;};
          triple_click = {threshold = 300;};
        };

        selection = {
          semantic_escape_chars = ",│`|:\"' ()[]{}<>";
        };
        hide_cursor_when_typing = false;
        live_config_reload = true;
        visual_bell = {
          duration = 0;
        };
      };
    };
  };
}
