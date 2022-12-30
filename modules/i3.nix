{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.services.josh.i3;

  xinitrc = pkgs.writeText "xinitrc" ''
    #!/bin/sh
    ${pkgs.xorg.xrandr}/bin/xrandr ${cfg.xrandr}
    ${pkgs.xorg.xset}/bin/xset r rate 200 50
    exec i3
  '';
in {
  options.services.josh.i3 = {
    enable = mkEnableOption "i3";

    xrandr = mkOption {
      type = types.lines;
    };
  };

  config = mkIf cfg.enable {
    services.xserver = {
      enable = true;
      layout = "us";
      dpi = 220;

      desktopManager = {
        xterm.enable = false;
        wallpaper.mode = "fill";
      };

      displayManager = {
        defaultSession = "none+i3";
        startx.enable = true;
      };

      windowManager.i3.enable = true;
    };

    systemd.tmpfiles.rules = [
      "L+ /home/josh/.xinitrc - - - - ${xinitrc}"
    ];
  };
}
