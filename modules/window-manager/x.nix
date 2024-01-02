{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.window-manager;

  wallimgs = builtins.fetchTarball {
    name = "wallimgs";
    url = "https://img.joshvanl.dev/wall/0004.tar.gz";
    sha256 = "04d8lqggaxf4kpn84gg021fv2k02xd0p6hfxzxgx00vca1wfggfx";
  };

  xmodmapF = pkgs.writeTextFile {
    name = "xmodmap";
    text = ''
      keycode 94 = grave asciitilde
    '' + optionalString cfg.arrowKeysMap60 ''
      clear Shift
      keysym Shift_R = Up Up Up Up Up Up Up
      add Shift = Shift_L
      clear mod1
      keysym Alt_R = Left Left Left Left Left Left Left
      add mod1 = Alt_L
      keysym Menu = Down Down Down Down Down Down Down
      clear Control
      keysym Control_R = Right Right Right Right Right Right Right
      add Control = Control_L
    '';
  };

  xconfSH = pkgs.writeShellApplication {
    name = "xconf.sh";
    runtimeInputs = with pkgs.xorg; [
      xset
      xmodmap
      setxkbmap
      xinput
    ];
    text = ''
      xset r rate 250 70
      xset s off -dpms
      setxkbmap -option caps:escape
    '' + optionalString cfg.xMouseSpeedDeceleration.enable ''
      xinput --set-prop ${toString cfg.xMouseSpeedDeceleration.prop} "Device Accel Constant Deceleration" ${toString cfg.xMouseSpeedDeceleration.deceleration}
    '' + ''
      xmodmap ${xmodmapF}
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

  mkSystemd = sys:
  let
    partOf = ["graphical-session.target"];
    after = optionals (builtins.hasAttr "after" sys) sys.after;
  in {
    Unit = {
      Description = sys.desc;
      PartOf = partOf;
      Requires = after;
      After = after;
    };
    Install.WantedBy = partOf;
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

    arrowKeysMap60 = mkEnableOption "arrow-keys-map-60";

    xMouseSpeedDeceleration = {
      enable = mkEnableOption "xinput-mouse-speed-deceleration";
      prop = mkOption {
        type = types.int;
        description = "Property ID of the mouse speed deceleration property";
      };
      deceleration = mkOption {
        type = types.float;
        description = "Mouse speed deceleration factor";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = with cfg; [
      {
        assertion = !xMouseSpeedDeceleration.enable || (xMouseSpeedDeceleration.prop != null && xMouseSpeedDeceleration.deceleration != null);
        message = "xMouseSpeedDeceleration: prop and deceleration must be set";
      }
    ];

    me.base.nix.specialisation.postCommands = [
      "systemctl --user start xconf.service"
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
      unitConfig = {
        RefuseManualStart = "no";
        StopWhenUnneeded = "no";
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
        };
        feh = mkSystemd {
          type = "oneshot";
          desc = "set wallpaper";
          exec = "${pkgs.feh}/bin/feh --no-fehbg --bg-scale --randomize ${wallimgs}";
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
