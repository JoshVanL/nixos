{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.window-manager;

  imgs = pkgs.fetchFromGitHub {
    owner = "joshvanl";
    repo = "imgs";
    rev = "c2be07ac9513f610e27775dce906967fbf407f82";
    hash = "sha256-AkeDin1qgoCJ0IGdrExbkTwOkkxM6kRtKjDmB88vZPw=";
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
    Install.WantedBy = ["graphical-session.target"];
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

    # Allow xinit to start graphical-session.target
    systemd.user.targets.graphical-session = {
      unitConfig.RefuseManualStart = false;
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
        };
        feh = mkSystemd {
          type = "oneshot";
          desc = "set wallpaper";
          exec = "${pkgs.feh}/bin/feh --no-fehbg --bg-center --randomize ${imgs}/jpg";
        };
        picom = mkSystemd {
          type = "simple";
          desc = "picom compositor";
          exec = "${pkgs.picom}/bin/picom";
        };
        xpropdate = mkSystemd {
          type = "simple";
          desc = "xpropdate: set WM_NAME to current datetime";
          exec = "${pkgs.xpropdate}/bin/xpropdate";
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
