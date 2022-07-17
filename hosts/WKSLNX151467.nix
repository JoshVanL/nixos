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
    hostName = "WKSLNX151467";
    hostId   = "49ab6f90";
    interfaces = {
      wlp0s20f3.useDHCP = true;
    };

    firewall.enable = false;
  };

  environment = {
    systemPackages = with pkgs; [
      brightnessctl
      kubectl
      kind
      helm
      cmctl
      python3
      imagemagick
      google-cloud-sdk
      go-jwt
      envsubst
      goreleaser
      postgresql
    ];

    etc = {
      "joshvanl/window-manager/kanshi.cfg" = {
        text = ''
          {
            output DP-1 mode 3849x1600  position 0,0
            output eDP-1 mode 3840x2400 scale 1.6 position 3840,0
          }

          {
            output DP-3 mode 3840x1600 position 0,0
            output eDP-1 mode 3840x2400 scale 1.6 position 3840,0
          }

          {
            output eDP-1 mode 3840x2400 scale 1.6 position 0,0
          }
        '';
        mode = "644";
      };
    };
  };

  # Optionally import private internal modules if the modules exist.
  imports = [
    #../modules/secure-boot
  ] ++ lib.optional (builtins.pathExists /keep/etc/nixos/modules/nixpkgs-internal) (./WKSLNX151467);

  nixpkgs = {
    config = {
      packageOverrides = super: {
        kind   = pkgs.callPackage /keep/etc/nixos/pkgs/kind {};
        helm   = pkgs.callPackage /keep/etc/nixos/pkgs/helm {};
        cmctl  = pkgs.callPackage /keep/etc/nixos/pkgs/cmctl {};
        go-jwt = pkgs.callPackage /keep/etc/nixos/pkgs/go-jwt {};
      };
    };

    overlays = [
      (self: super: {
        somestatus = super.somestatus.overrideAttrs (attrs: rec {
          patches = attrs.patches ++ [
            (super.fetchpatch {
              name = "somebar.joshvanl-module-battery";
              url  = "https://raw.githubusercontent.com/joshvanl/somestatus/d71bf508a23cf436344ed7141f27b4390440565d/patches/001-module-battery.patch";
              hash = "sha256-9U83CJ6UJJ6KrrRVxn/6OEorijUF2VcD2+f4TG+RwQ0=";
            })
            (super.fetchpatch {
              name = "somebar.joshvanl-module-backlight";
              url  = "https://raw.githubusercontent.com/joshvanl/somestatus/c2ccb473abc40b9db0beb04c9fe659672bc0959f/patches/002-module-backlight-intel.patch";
              hash = "sha256-R6NI0SPvDWERvD2GObe6Dk/2GODQkxjnSwxfFTZdhl4=";
            })
          ];
        });
      })
    ];
  };
}
