{ lib, pkgs, config, dwm, ... }:

with lib;
let
  cfg = config.me.window-manager;

  wallpaper = pkgs.fetchurl {
    url = "https://github.com/JoshVanL/imgs/raw/main/wallpaper-3.jpg";
    hash = "sha256-d+2uu+/ZtjJU34tNjidbMHGY6UDjPO7R2tA8VrCHWIA=";
  };

  xinitrcSH = pkgs.writeShellApplication {
    name = "xinitrc.sh";
    runtimeInputs = with pkgs; [
      xorg.xrandr
      xorg.xset
      xorg.xmodmap
      xorg.setxkbmap
      feh
      picom
      xorg.xprop
      pkgs.dwm
    ];
    text = ''
      xrandr ${cfg.xrandrArgs}
      xset r rate 250 70
      xset s off -dpms
      setxkbmap -option caps:escape
      xmodmap -e 'keycode 94 = grave asciitilde'
      feh --bg-fill ${wallpaper}
      picom &
      xprop -root -set WM_NAME "-"
      dwm
    '';
  };
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


    home-manager.users.${config.me.username} = {
      home = {
        packages = with pkgs; [
          xclip
          arandr
          evince
        ];

        file.".xinitrc".source = "${xinitrcSH}/bin/xinitrc.sh";
      };

      programs.zsh.shellAliases = {
        x = "startx";
      };
    };
  };
}
