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
        patches = attrs.patches ++ [ ];
      });
    })
  ];
}

