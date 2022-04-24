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
      "d /persist/home/.config      0755 josh wheel - -"

      # Locals to pre-create with correct perms.
      "d /home/josh/.config      0755 josh wheel - -"
      "d /home/josh/.local       0755 josh wheel - -"
      "d /home/josh/.local/share 0755 josh wheel - -"
      "d /root/.config           0755 root root - -"

      # Configs to save.
      "L+ /home/josh/.config/alacritty - - - - /persist/etc/nixos/dotfiles/.config/alacritty"
      "L+ /home/josh/.config/nixpkgs   - - - - /persist/etc/nixos/dotfiles/nixpkgs"
      "L+ /home/josh/.config/oh-my-zsh - - - - /persist/etc/nixos/dotfiles/.config/oh-my-zsh"
      "L+ /root/.config/alacritty - - - - /persist/etc/nixos/dotfiles/.config/alacritty"
      "L+ /root/.config/nixpkgs   - - - - /persist/etc/nixos/dotfiles/nixpkgs"
      "L+ /root/.config/oh-my-zsh - - - - /persist/etc/nixos/dotfiles/.config/oh-my-zsh"

      # /etc to save.
      "d  /persist/etc/NetworkManager/system-connections  0755 josh wheel - -"
      "L+ /etc/NetworkManager/system-connections          - - - - /persist/etc/NetworkManager/system-connections"

      # Fonts.
      "L+ /root/.local/share/fonts      - - - - /persist/etc/nixos/dotfiles/fonts"
      "L+ /home/josh/.local/share/fonts - - - - /persist/etc/nixos/dotfiles/fonts"

      # Histories/Caches.
      "L+ /home/josh/.zsh_history - - - - /persist/home/.zsh_history"
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
      git
      vim_configurable
      wget
      firefox
      termite
      alacritty
      gtk-engine-murrine
      gtk_engines
      gsettings-desktop-schemas
      lxappearance
      cryptsetup
      #go
      kubectl
      killall
    ];
  };
}
