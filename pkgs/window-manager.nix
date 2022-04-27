{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    swaybg
    wofi

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
      ];
    }))
  ];
}
