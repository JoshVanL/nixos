{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./yubikey.nix
    ./dotfiles/nixpkgs/home.nix
  ];

  nix = {
    allowedUsers = [ "root" "josh"];
    extraOptions = ''
      experimental-features = nix-command
    '';
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/persist/etc/nixos/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };

  system.stateVersion = "nixos";

  boot  = {
    # Clense with fire.
    initrd.postDeviceCommands = lib.mkAfter ''
      zfs rollback -r rpool/local/root@blank
    '';
    zfs = {
      requestEncryptionCredentials = true;
    };

    kernelParams = [ "nohibernate" ];

    supportedFilesystems = [ "vfat" "zfs" ];
    loader = {
      # Use the systemd-boot EFI boot loader.
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
      };
    };
  };

  # Needed for user passwords.
  fileSystems."/persist".neededForBoot = true;

  networking = {
    hostName = "thistle";
    hostId   = "94ec2b8d";
    useDHCP  = false;
    interfaces = {
      enp1s0.useDHCP = true;
      enp2s0f0.useDHCP = true;
      wlp3s0.useDHCP = true;
    };

    networkmanager.enable = true;
    firewall.enable = false;
    wireless.userControlled.enable = false;

    nameservers = [
      "8.8.8.8"
      "8.8.4.4"
    ];
  };

  # ZFS maintenance settings
  services = {
    zfs = {
      autoScrub = {
        enable = true;
        pools  = [ "rpool" ];
      };
      autoSnapshot =  {
        enable = true;
      };
      trim.enable = true;
    };

    interception-tools = {
      enable = true;
      plugins = [ pkgs.interception-tools-plugins.caps2esc ];
      udevmonConfig = ''
        - JOB: "${pkgs.interception-tools}/bin/intercept -g $DEVNODE | ${pkgs.interception-tools-plugins.caps2esc}/bin/caps2esc | ${pkgs.interception-tools}/bin/uinput -d $DEVNODE"
          DEVICE:
            EVENTS:
              EV_KEY: [KEY_CAPSLOCK, KEY_ESC]
      '';
    };
  };

  # Set your time zone.
  time.timeZone = "Europe/London";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
  };

  users = {
    defaultUserShell = pkgs.zsh;
    mutableUsers = false;
    users = {
      josh = {
        isNormalUser = true;
        uid = 1000;
        createHome = true;
        home = "/home/josh";
        group = "users";
        extraGroups = [ "wheel" "networkmanager" ];
        passwordFile = "/persist/etc/users/josh";
      };
      root = {
        hashedPassword = "!";
      };
    };
  };

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      swaylock
      swayidle
      wl-clipboard
      mako # notification daemon
      alacritty
      dmenu # Dmenu is the default in the config but i recommend wofi since its wayland native
      feh
    ];
  };
  console.useXkbConfig = true;

  # Link to configs.
  systemd.tmpfiles.rules = [
      # /persist to maintain.
      "d /persist/home              0755 josh wheel - -"
      "d /persist/home/go           0755 josh wheel - -"
      "d /persist/home/.gnupg       0755 josh wheel - -"

      # Locals to pre-create with correct perms.
      "d /home/josh/.config      0755 josh wheel - -"
      "d /home/josh/.local       0755 josh wheel - -"
      "d /home/josh/.local/share 0755 josh wheel - -"
      "d /root/.config           0755 root root - -"

      # /etc to save.
      "d  /persist/etc/NetworkManager/system-connections  0755 josh wheel - -"
      "L+ /etc/NetworkManager/system-connections          - - - - /persist/etc/NetworkManager/system-connections"

      # Fonts.
      "L+ /root/.local/share/fonts      - - - - /persist/etc/nixos/dotfiles/fonts"
      "L+ /home/josh/.local/share/fonts - - - - /persist/etc/nixos/dotfiles/fonts"

      # Histories/Caches.
      "L+ /home/josh/.zsh_history - - - - /persist/home/.zsh_history"
      "L+ /home/josh/.gnupg       - - - - /persist/home/.gnupg"
      "L+ /home/josh/go	          - - - - /persist/home/go"
  ];

  fonts.fonts = with pkgs; [
    powerline-fonts
  ];

  environment = {
    etc = {
      "sway/config".source     = /persist/etc/nixos/dotfiles/.config/sway/config;
    };
    sessionVariables = rec {
      XDG_DATA_HOME = "\${HOME}/.local/share";
    };
    systemPackages = with pkgs; [
      # base
      cryptsetup
      wget
      killall
      git
      vim_configurable
      firefox
      chromium

      # window-manager
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
            name = "dwl.vanitygaps";
            url  = "https://github.com/djpohly/dwl/compare/main...Sevz17:vanitygaps.patch";
            hash = "sha256-6Xb0IncQxyBXSGcWnw/OWq2upSxzJYgfEBhU7DU20oA=";
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
            hash = "sha256-gow4ND3nS+glzJA9Cm8Gt6oncRHJW31c98T5fQFbZuI=";
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
        ];
      }))
      swaybg
      wofi

      # work
      gnumake
      go_1_18
      kubectl
      calc
    ];
  };
}
