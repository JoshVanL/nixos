{ lib, pkgs, config, dwm, ... }:

with lib;
let
  cfg = config.services.josh.dwm;

  wallpaper = pkgs.fetchurl {
    url = "https://github.com/JoshVanL/imgs/raw/main/wallpaper-2.jpg";
    hash = "sha256-8JkbnfF033XPiBETWQ5G6RCmBmXtx9f/SsfYU7ObnwY=";
  };

  xinitrc = pkgs.writeText "xinitrc" ''
    #!/bin/sh
    ${pkgs.xorg.xrandr}/bin/xrandr ${cfg.xrandr}
    ${pkgs.xorg.xset}/bin/xset r rate 250 70
    ${pkgs.feh}/bin/feh --bg-fill ${wallpaper}
    ${pkgs.picom}/bin/picom &
    ${pkgs.xorg.xprop}/bin/xprop -root -set WM_NAME "-"
    ${pkgs.dwm}/bin/dwm
  '';
in {
  options.services.josh.dwm = {
    enable = mkEnableOption "dwm";

    xrandr = mkOption {
      type = types.lines;
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      xclip
      arandr
      rofi
    ];

    services = {
      xserver = {
        enable = true;
        layout = "us";
        dpi = 220;

        desktopManager = {
          xterm.enable = false;
          wallpaper.mode = "fill";
        };

        displayManager = {
          defaultSession = "none+dwm";
          startx.enable = true;
        };

        windowManager.dwm.enable = true;
      };
    };

    fonts.fonts = with pkgs; [
      font-awesome
    ];

    systemd.tmpfiles.rules = [
      "L+ /home/josh/.xinitrc - - - - ${xinitrc}"
    ];
  };
}
