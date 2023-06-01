{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.window-manager;

  wallpaper = pkgs.fetchurl {
    url = "https://github.com/JoshVanL/imgs/raw/main/wallpaper-3.jpg";
    hash = "sha256-d+2uu+/ZtjJU34tNjidbMHGY6UDjPO7R2tA8VrCHWIA=";
  };

  xconfSH = pkgs.writeShellApplication {
    name = "xconf.sh";
    runtimeInputs = with pkgs; [
      xorg.xset
      xorg.xmodmap
      xorg.setxkbmap
    ];
    text = ''
      xset r rate 250 70
      xset s off -dpms
      setxkbmap -option caps:escape
      xmodmap -e 'keycode 94 = grave asciitilde'
    '';
  };

  xinitrcSH = pkgs.writeShellApplication {
    name = ".xinitrc";
    text = ''
      ${pkgs.systemdMinimal}/bin/systemctl --user start graphical-session.target
      ${pkgs.dwm}/bin/dwm
      ${pkgs.systemdMinimal}/bin/systemctl --user stop graphical-session.target
    '';
  };

  mkSystemd = sys: {
    Unit = {
      Description = sys.desc;
      PartOf = ["graphical-session.target"];
    };
    Install = {
      WantedBy = ["graphical-session.target"];
      After = sys.after or [];
    };
    Service = {
      Environment = [ "DISPLAY=:0" ];
      Type = sys.type;
      ExecStart = sys.exec;
    };
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
      systemd.user.services = {
        xrandr = mkSystemd {
          type = "oneshot";
          desc = "configure xrandr";
          exec = "${pkgs.xorg.xrandr}/bin/xrandr ${cfg.xrandrArgs}";
        };
        xconf = mkSystemd {
          type = "oneshot";
          desc = "configure X";
          exec = "${xconfSH}/bin/xconf.sh";
          after = ["xrandr.service"];
        };
        feh = mkSystemd {
          type = "oneshot";
          desc = "set wallpaper";
          exec = "${pkgs.feh}/bin/feh --bg-fill ${wallpaper} --no-fehbg";
          after = ["xrandr.service"];
        };
        picom = mkSystemd {
          type = "simple";
          desc = "picom compositor";
          exec = "${pkgs.picom}/bin/picom";
          after = ["xrandr.service"];
        };
        xpropdate = mkSystemd {
          type = "simple";
          desc = "xpropdate: set WM_NAME to current datetime";
          exec = "${pkgs.xpropdate}/bin/xpropdate";
          after = ["xrandr.service"];
        };
      };

      home = {
        packages = with pkgs; [
          xclip
          arandr
          evince
        ];

        file.".xinitrc".source = "${xinitrcSH}/bin/.xinitrc";
      };

      programs.zsh.shellAliases = {
        x = "startx";
      };
    };
  };
}
