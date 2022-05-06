{ lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    wl-clipboard
    swaybg
    wofi
    waybar

    (import /persist/etc/nixos/nixpkgs/somebar/default.nix {
      lib  = lib;
      pkgs = pkgs;
      applyPatches = [
        (fetchpatch {
          name = "somebar.joshvanl-ipc";
          url  = "https://raw.githubusercontent.com/JoshVanL/somebar/joshvanl-patches/patches/000-ipc.patch";
          hash = "sha256-+aXA9CcP729cuxpfUqL4HWsITjFW8USs5xs3Lv673C4=";
        })
        (fetchpatch {
          name = "somebar.joshvanl-config-colours";
          url  = "https://raw.githubusercontent.com/joshvanl/somebar/joshvanl-patches/patches/001-config-colours.patch";
          hash = "sha256-ZHUs9rXNwKmn5l0oPeFKaEFQvygOycBHPh/UXlx9m/Q=";
        })
        (fetchpatch {
          name = "somebar.joshvanl-hide-empty-tags";
          url  = "https://raw.githubusercontent.com/joshvanl/somebar/joshvanl-patches/patches/002-hide-empty-tags.patch";
          hash = "sha256-4nAN1UpryyPAr1nvx/iWUWbt42gsD5eN5wEdZXX2fxE=";
        })
      ];
    })

    (dwl.overrideAttrs (oldAttrs: rec {
      version = "0.3.2+canary";
      src = fetchFromGitHub {
        owner = "djpohly";
        repo = "dwl";
        rev = "a48ce99e6a3c0dda331781942995a85ba8e438a0";
        hash = "sha256-E561th6ki5rNMy3qODzw3uZw3nrBbl/52pylp7dpdzg=";
      };
      patches = [
        (fetchpatch {
          name = "dwl.joshvanl-vanity-gaps";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0000-vanity-gaps.patch";
          hash = "sha256-MPnYUOSG1x74zKaJUyeRuP905mRn3jq2hwGYaK12/yI=";
        })
        (fetchpatch {
          name = "dwl.joshvanl-mod-key-logo";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0001-mod-key-logo.patch";
          hash = "sha256-mADTS6fdgMLndlIluKyykjw0t/d2HbkfUP613qgKFPA=";
        })
        (fetchpatch {
          name = "dwl.joshvanl-colours";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0002-colours.patch";
          hash = "sha256-yRAwp4Ff6y6PQAUKEthfKUGkIxqYfkuz35INDFPtZx4=";
        })
        (fetchpatch {
          name = "dwl.joshvanl-firefox-wofi";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0003-firefox-wofi.patch";
          hash = "sha256-BhdbQ5CmMFVC7+XAjrse7RvfxctALp3e/OdrkfkM0tc=";
        })
        (fetchpatch {
          name = "dwl.joshvanl-repeat-rate";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0004-repeat-rate.patch";
          hash = "sha256-6tunCJlffKk4SszsNHbaYXNCrDzuZFOaUQxlXLh4ImI=";
        })
        (fetchpatch {
          name = "dwl.joshvanl-window-change-focus";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0005-window-change-focus.patch";
          hash = "sha256-iYKIjsm8Lhjm5Q5aZ0g9cUPao0qh8aIo4Pkb1aF6XVE=";
        })
        (fetchpatch {
          name = "dwl.joshvanl-no-window-rules";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0006-no-window-rules.patch";
          hash = "sha256-pbR5rDYjWXbZ1QrAQm7cjuB/U0OsQJUO5r2pNvcEJok=";
        })
        (fetchpatch {
          name = "dwl.joshvanl-chromium";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0007-chromium.patch";
          hash = "sha256-PNRD3SSWkPIAthxyOqYGF/cYVCgQx97PlxzY4/16nUw=";
        })
        (fetchpatch {
          name = "dwl.joshvanl-main-on-right";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0008-main-on-right.patch";
          hash = "sha256-QVkwj05Yp/nyfSN9C95AzWAcEbifmfiEn8UZpoPrEh4=";
        })
        (fetchpatch {
          name = "dwl.joshvanl-xkb-rule-caps-escape";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0009-xkb-rule-caps-escape.patch";
          hash = "sha256-uIx5SYuR0qu3RUqldqAzzKcti8HTBeCBIXi6NE2GdBQ=";
        })
        (fetchpatch {
          name = "dwl.joshvanl-remove-monocol-layout";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0010-remove-monocol-layoput.patch";
          hash = "sha256-5ogfQoFcCgH3yEbzzWRuqziwGv8BVoDxvIda6xZ9kws=";
        })
        (fetchpatch {
          name = "dwl.joshvanl-movestack";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0011-movestack.patch";
          hash = "sha256-MpkvfdQqJI0N6EEZrFFhLCux55yFGUaPLybtvh1IFt0=";
        })
        (fetchpatch {
          name = "dwl.joshvanl-follow-move-window";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0012-follow-move-window.patch";
          hash = "sha256-4cKft9FzJUUdDIKsIHigDygf2utF/d5rcydgX/oSV3k=";
        })
        (fetchpatch {
          name = "dwl.joshvanl-remove-incmaster";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0013-remove-incmaster.patch";
          hash = "sha256-Xvov3THpGNdhGc+U95apB3fMtnRvl4L3B3P3wn8c8vI=";
        })
        (fetchpatch {
          name = "dwl.joshvanl-pinentry-floating";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0014-pinentry-floating.patch";
          hash = "sha256-HCR4TCWAWIGoIsAMvWVzx2Ff9EyZ390H2ODqf6aGyaE=";
        })
        (fetchpatch {
          name = "dwl.joshvanl-wayland-ipc";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0015-wayland-ipc.patch";
          hash = "sha256-jjh1YeROFeJn/Ae0pKu6G2Ds8JFw6JjHWtBm5aqaxqE=";
        })
        (fetchpatch {
          name = "dwl.joshvanl-fix-segfault";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0016-fix-segfault.patch";
          hash = "sha256-CCdHQ8856IZs3QKISyilRkKc9TCbEXv21NzVRbRfN3s=";
        })
        (fetchpatch {
          name = "dwl.add-tag-10";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0017-add-tag-10.patch";
          hash = "sha256-uQJrQbKsICQKdXzJ5ThdsYjclFodgJL053jZiQDzL2w=";
        })
        (fetchpatch {
          name = "dwl.fix-another-seg-fault";
          url  = "https://raw.githubusercontent.com/joshvanl/dwl/joshvanl-patches/patches/0018-fix-another-seg-fault.patch";
          hash = "sha256-fLebNLevVbdCrkJXdSbqgIdIEPsJR+F7J8YW3ag+y0I=";
        })
      ];
    }))
  ];

  environment.etc = {
    "window-manager/start.sh" = {
      text = ''
        #!/usr/bin/env bash

        # TODO: find a way to use 'dwl -c' without freezing.
        dwl >/dev/null <&- &
        sleep 0.6
        swaybg -i $HOME/imgs/system/wallpaper.jpg <&- &
        somebar <&-
      '';

      mode = "755";
    };
  };
}