{ lib, pkgs, ... }:

{
  networking = {
    hostName = "WKSLNX151467";
    hostId   = "49ab6f90";
    interfaces = {
      wlp0s20f3.useDHCP = true;
    };
  };

  nixpkgs.overlays = [
    (self: super: {
      somestatus = super.somestatus.overrideAttrs (attrs: rec {
        patches = attrs.patches ++ [
          (super.fetchpatch {
            name = "somebar.joshvanl-module-battery";
            url  = "https://raw.githubusercontent.com/joshvanl/somestatus/d71bf508a23cf436344ed7141f27b4390440565d/patches/001-module-battery.patch";
            hash = "sha256-9U83CJ6UJJ6KrrRVxn/6OEorijUF2VcD2+f4TG+RwQ0=";
          })
          (super.fetchpatch {
            name = "somebar.joshvanl-module-battery";
            url  = "https://raw.githubusercontent.com/joshvanl/somestatus/d71bf508a23cf436344ed7141f27b4390440565d/patches/002-module-backlight-intel.patch";
            hash = "sha256-NZdMMH8ouo0KAJH85EKoV8VG5+pjpAeXhomPoYRUbBg=";
          })
        ];
      });
    })
  ];
}

