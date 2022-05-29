{ lib, pkgs, ... }:

{
  boot.loader = {
    # Use the systemd-boot EFI boot loader.
    systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = true;
    };
  };

  networking = {
    hostName = "thistle";
    hostId   = "94ec2b8d";
    interfaces = {
      enp1s0.useDHCP = true;
      enp2s0f0.useDHCP = true;
      wlp3s0.useDHCP = true;
    };

    firewall.enable = false;
  };

  nixpkgs.overlays = [
    (self: super: {
      somestatus = super.somestatus.overrideAttrs (attrs: rec {
        patches = attrs.patches ++ [ ];
      });
    })
  ];

  environment.etc = {
    "joshvanl/window-manager/kanshi.cfg" = {
      text = ''
        { }
      '';
      mode = "644";
    };
  };
}

