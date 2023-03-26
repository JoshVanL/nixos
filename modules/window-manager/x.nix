{ lib, pkgs, config, dwm, ... }:

with lib;
let
  cfg = config.me.window-manager;

  wallpaper = pkgs.fetchurl {
    url = "https://github.com/JoshVanL/imgs/raw/main/wallpaper-2.jpg";
    hash = "sha256-8JkbnfF033XPiBETWQ5G6RCmBmXtx9f/SsfYU7ObnwY=";
  };

  xinitrc = pkgs.writeShellScript "xinitrc.sh" ''
    ${pkgs.xorg.xrandr}/bin/xrandr ${cfg.xrandrArgs}
    ${pkgs.xorg.xset}/bin/xset r rate 250 70
    ${pkgs.xorg.xset}/bin/xset s off -dpms
    ${pkgs.xorg.xmodmap}/bin/xmodmap -e 'keycode 94 = grave asciitilde'
    ${pkgs.xorg.setxkbmap}/bin/setxkbmap -option caps:escape
    ${pkgs.feh}/bin/feh --bg-fill ${wallpaper}
    ${pkgs.picom}/bin/picom &
    ${pkgs.xorg.xprop}/bin/xprop -root -set WM_NAME "-"
    ${pkgs.dwm}/bin/dwm
  '';
in {
  options.me.window-manager = {
    enable = mkEnableOption "window-manager";

    xrandrArgs = mkOption {
      type = types.lines;
    };

    naturalScrolling = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
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

        libinput.enable = cfg.naturalScrolling;
        extraConfig = mkIf cfg.naturalScrolling ''
          Section "InputClass"
            Identifier "libinput pointer catchall"
            MatchDevicePath "/dev/input/event*"
            Driver "libinput"
            Option "NaturalScrolling" "true"
          EndSection
        '';
      };

      pipewire = {
        enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
        pulse.enable = true;
        jack.enable = true;
      };
    };


    home-manager.users.${config.me.base.username}.home = {
      packages = with pkgs; [
        xclip
        arandr
        evince
      ];

      file.".xinitrc".source = xinitrc;
    };
  };
}
