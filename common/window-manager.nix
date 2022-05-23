{ lib, pkgs, ... }:

{
  environment.etc = {
    "joshvanl/window-manager/start.sh" = {
      text = ''
        #!/usr/bin/env bash

        rm -f $HOME/.zsh_history && ln -s /persist/home/.zsh_history $HOME/.zsh_history

        # TODO: find a way to use 'dwl -c' without freezing.
        XDG_CURRENT_DESKTOP=Wayfire dbus-run-session dwl >/dev/null <&- &
        sleep 0.6
        swaybg -i $HOME/imgs/system/wallpaper.jpg <&- &
        somebar <&- &
        sleep 0.6
        kanshi --config /etc/joshvanl/window-manager/kanshi.cfg >/dev/null <&- &
        sleep 1
        dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Wayfire
        systemctl --user stop pipewire wireplumber xdg-desktop-portal xdg-desktop-portal-wlr
        systemctl --user start wireplumber
        while somestatus; do; break; done
      '';

      mode = "755";
    };
  };

  environment.systemPackages = with pkgs; [
    wl-clipboard
    swaybg
    wofi
    waybar
    kanshi
    wdisplays
    somestatus
    somebar
    dwl
  ];

  nixpkgs.config.packageOverrides = super: {
    somestatus = pkgs.callPackage /keep/etc/nixos/nixpkgs/somestatus {};
    somebar    = pkgs.callPackage /keep/etc/nixos/nixpkgs/somebar {
      patches = [
        (super.fetchpatch {
          name = "somebar.joshvanl-ipc";
          url  = "https://raw.githubusercontent.com/joshvanl/somebar/joshvanl-patches/patches/000-ipc.patch";
          hash = "sha256-+aXA9CcP729cuxpfUqL4HWsITjFW8USs5xs3Lv673C4=";
        })
        (super.fetchpatch {
          name = "somebar.joshvanl-config-colours";
          url  = "https://raw.githubusercontent.com/joshvanl/somebar/joshvanl-patches/patches/001-config-colours.patch";
          hash = "sha256-ZHUs9rXNwKmn5l0oPeFKaEFQvygOycBHPh/UXlx9m/Q=";
        })
        (super.fetchpatch {
          name = "somebar.joshvanl-hide-empty-tags";
          url  = "https://raw.githubusercontent.com/joshvanl/somebar/joshvanl-patches/patches/002-hide-empty-tags.patch";
          hash = "sha256-4nAN1UpryyPAr1nvx/iWUWbt42gsD5eN5wEdZXX2fxE=";
        })
        (super.fetchpatch {
          name = "somebar.joshvanl-status-text-invert";
          url  = "https://raw.githubusercontent.com/joshvanl/somebar/joshvanl-patches/patches/003-status-text-invert.patch";
          hash = "sha256-k07fViaNVqMgd23worXLCXx9Im7/lWdnM+e9jL8kYYQ=";
        })
      ];
    };
    dwl = super.dwl.overrideAttrs (_: rec {
      version = "0.3.2+canary.1";
      src = super.fetchFromGitHub {
        owner = "djpohly";
        repo  = "dwl";
        rev   = "22bd75226bc897a3b2ad90f36883ff489d435eb4";
        hash  = "sha256-C6PS4F2Rf5ueHDE22IDMaLu1cUbccmQbacHVqKcGjlg=";
      };
      patches = [
        (super.fetchpatch {
          name = "dwl.joshvanl-vanity-gaps";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0000-vanity-gaps.patch";
          hash = "sha256-MPnYUOSG1x74zKaJUyeRuP905mRn3jq2hwGYaK12/yI=";
        })
        (super.fetchpatch {
          name = "dwl.joshvanl-mod-key-logo";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0001-mod-key-logo.patch";
          hash = "sha256-mADTS6fdgMLndlIluKyykjw0t/d2HbkfUP613qgKFPA=";
        })
        (super.fetchpatch {
          name = "dwl.joshvanl-colours";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0002-colours.patch";
          hash = "sha256-yRAwp4Ff6y6PQAUKEthfKUGkIxqYfkuz35INDFPtZx4=";
        })
        (super.fetchpatch {
          name = "dwl.joshvanl-firefox-wofi";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0003-firefox-wofi.patch";
          hash = "sha256-BhdbQ5CmMFVC7+XAjrse7RvfxctALp3e/OdrkfkM0tc=";
        })
        (super.fetchpatch {
          name = "dwl.joshvanl-repeat-rate";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0004-repeat-rate.patch";
          hash = "sha256-6tunCJlffKk4SszsNHbaYXNCrDzuZFOaUQxlXLh4ImI=";
        })
        (super.fetchpatch {
          name = "dwl.joshvanl-window-change-focus";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0005-window-change-focus.patch";
          hash = "sha256-iYKIjsm8Lhjm5Q5aZ0g9cUPao0qh8aIo4Pkb1aF6XVE=";
        })
        (super.fetchpatch {
          name = "dwl.joshvanl-no-window-rules";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0006-no-window-rules.patch";
          hash = "sha256-pbR5rDYjWXbZ1QrAQm7cjuB/U0OsQJUO5r2pNvcEJok=";
        })
        (super.fetchpatch {
          name = "dwl.joshvanl-chromium";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0007-chromium.patch";
          hash = "sha256-PNRD3SSWkPIAthxyOqYGF/cYVCgQx97PlxzY4/16nUw=";
        })
        (super.fetchpatch {
          name = "dwl.joshvanl-main-on-right";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0008-main-on-right.patch";
          hash = "sha256-QVkwj05Yp/nyfSN9C95AzWAcEbifmfiEn8UZpoPrEh4=";
        })
        (super.fetchpatch {
          name = "dwl.joshvanl-xkb-rule-caps-escape";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0009-xkb-rule-caps-escape.patch";
          hash = "sha256-uIx5SYuR0qu3RUqldqAzzKcti8HTBeCBIXi6NE2GdBQ=";
        })
        (super.fetchpatch {
          name = "dwl.joshvanl-remove-monocol-layout";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0010-remove-monocol-layoput.patch";
          hash = "sha256-5ogfQoFcCgH3yEbzzWRuqziwGv8BVoDxvIda6xZ9kws=";
        })
        (super.fetchpatch {
          name = "dwl.joshvanl-movestack";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0011-movestack.patch";
          hash = "sha256-MpkvfdQqJI0N6EEZrFFhLCux55yFGUaPLybtvh1IFt0=";
        })
        (super.fetchpatch {
          name = "dwl.joshvanl-follow-move-window";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0012-follow-move-window.patch";
          hash = "sha256-4cKft9FzJUUdDIKsIHigDygf2utF/d5rcydgX/oSV3k=";
        })
        (super.fetchpatch {
          name = "dwl.joshvanl-remove-incmaster";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0013-remove-incmaster.patch";
          hash = "sha256-Xvov3THpGNdhGc+U95apB3fMtnRvl4L3B3P3wn8c8vI=";
        })
        (super.fetchpatch {
          name = "dwl.joshvanl-pinentry-floating";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0014-pinentry-floating.patch";
          hash = "sha256-HCR4TCWAWIGoIsAMvWVzx2Ff9EyZ390H2ODqf6aGyaE=";
        })
        (super.fetchpatch {
          name = "dwl.joshvanl-wayland-ipc";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0015-wayland-ipc.patch";
          hash = "sha256-jjh1YeROFeJn/Ae0pKu6G2Ds8JFw6JjHWtBm5aqaxqE=";
        })
        (super.fetchpatch {
          name = "dwl.joshvanl-add-tag-10";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0017-add-tag-10.patch";
          hash = "sha256-uQJrQbKsICQKdXzJ5ThdsYjclFodgJL053jZiQDzL2w=";
        })
        (super.fetchpatch {
          name = "dwl.joshvanl-fix-another-seg-fault";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0018-fix-another-seg-fault.patch";
          hash = "sha256-fLebNLevVbdCrkJXdSbqgIdIEPsJR+F7J8YW3ag+y0I=";
        })
        (super.fetchpatch {
          name = "dwl.joshvanl-microphone-mute-command";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0019-mute-command.patch";
          hash = "sha256-oyi11Bllsj182izBWnvFf3PwfgANew5EstEHPFHhanA=";
        })
        (super.fetchpatch {
          name = "dwl.joshvanl-natural-scrolling";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0020-trackpad-natural-scrolling.patch";
          hash = "sha256-c/ItljW3t69FDrcm6kEGNRTu1MQmoeb3HZTwcUhSZiM=";
        })
        (super.fetchpatch {
          name = "dwl.joshvanl-volume-buttons";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0021-volume-buttons.patch";
          hash = "sha256-tXyQwkIEaPiSdfUGdqMaGIZRTEt6oPbpnvjbxRhf5vA=";
        })
        (super.fetchpatch {
          name = "dwl.joshvanl-brightness-buttons";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0022-brightness-buttons.patch";
          hash = "sha256-VNxX3tyLnS3h6lshmF5I59NQ5xV8dIUunoyytLqMgls=";
        })
      ];
    });
  };
}
