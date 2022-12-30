{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.services.josh.i3;
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
        sessionCommands = ''
          ${pkgs.xorg.xset}/bin/xset r rate 300 30;
        '';
      };

      windowManager.i3.enable = true;
    };

    systemd.tmpfiles.rules = [
      "L+ /home/josh/.xinitrc - - - - /etc/josh/.xinitrc"
    ];
    environment.etc."josh/.xinitrc" = {
      mode = "0444";
      text = ''
        xrandr ${cfg.xrandr}
        exec i3
      '';
    };
  };
}
