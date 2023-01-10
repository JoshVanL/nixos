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
    hostName = "purple";
    hostId   = "49ab6f90";

    firewall.enable = false;
  };

  services = {
    blueman.enable = true;
  };

  hardware = {
    bluetooth.enable = true;
  };

  services.xserver = {
    enable = true;
    desktopManager.xterm.enable = false;
    layout = "us";
    autorun = false;
    #desktopManager.default = "none";
    displayManager.defaultSession = "none+i3";
    windowManager.i3 = {
      enable = true;
    };
    displayManager.sessionCommands = "sleep 5 && ${pkgs.xorg.xmodmap}/bin/xmodmap -e 'keycode 94 = grave asciitilde'";
    displayManager.startx.enable = true;
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
      postgresql
      step
      git-crypt
      age
      terraform
      dive
      vcert
      protobuf
      go-protobuf
      go-protobuf-grpc
      gomarkdoc
      paranoia
    ];

    etc = {
      "joshvanl/window-manager/kanshi.cfg" = {
        text = ''
          {
            output Virtual-1 mode 3024x1890@60Hz scale 1.4 position 0,0
          }
        '';
        mode = "644";
      };
    };
  };

  nixpkgs = {
    config = {
      packageOverrides = super: {
        helm   = pkgs.callPackage /keep/etc/nixos/pkgs/helm {};
        go-jwt = pkgs.callPackage /keep/etc/nixos/pkgs/go-jwt {};
        vcert = pkgs.callPackage /keep/etc/nixos/pkgs/vcert {};
        go-protobuf = pkgs.callPackage /keep/etc/nixos/pkgs/go-protobuf {};
        go-protobuf-grpc = pkgs.callPackage /keep/etc/nixos/pkgs/go-protobuf-grpc {};
        step = pkgs.callPackage /keep/etc/nixos/pkgs/step-cli {};
        gomarkdoc = pkgs.callPackage /keep/etc/nixos/pkgs/gomarkdoc {};
        paranoia = pkgs.callPackage /keep/etc/nixos/pkgs/paranoia {};
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