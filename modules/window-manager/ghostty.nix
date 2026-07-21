{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.window-manager;

in {
  config = mkIf config.me.window-manager.enable {
    home-manager.users.${config.me.username}.programs.ghostty = {
      enable = true;
      # Parallels' virtual GPU (virgl) only exposes OpenGL 4.0 which is too
      # old for ghostty's renderer. Mesa software rendering (llvmpipe)
      # provides 4.5 and is fast enough for a terminal.
      package = mkIf config.me.base.parallels.enable (pkgs.symlinkJoin {
        name = "ghostty-soft-gl";
        paths = [ pkgs.ghostty ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/ghostty --set LIBGL_ALWAYS_SOFTWARE 1
        '';
        # home-manager's config reload hook uses lib.getExe, which
        # derives the binary name from the derivation name
        meta.mainProgram = "ghostty";
      });
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
        window-decoration = false;
        theme = "joshvanl";
        bold-color = "bright";
        mouse-hide-while-typing = true;
        term = "xterm-256color";
        shell-integration-features = "no-cursor";
      };
    };
  };
}
