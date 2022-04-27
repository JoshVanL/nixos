{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./yubikey.nix
    ./nixpkgs/home.nix
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
      "1.1.1.1"
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
  };

  # Set your time zone.
  time.timeZone = "Europe/London";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
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

  # Link to configs.
  systemd.tmpfiles.rules = [
      # /persist to maintain.
      "d /persist/home              0755 josh wheel - -"
      "d /persist/home/go           0755 josh wheel - -"
      "d /persist/home/.gnupg       0755 josh wheel - -"
      "d /persist/home/.ssh         0700 josh wheel - -"
      "d /persist/home/.mozilla     0700 josh wheel - -"

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
      "L+ /home/josh/.ssh	        - - - - /persist/home/.ssh"
      "L+ /home/josh/.mozilla	    - - - - /persist/home/.mozilla"
  ];

  fonts.fonts = with pkgs; [
    powerline-fonts
  ];

  environment = {
    sessionVariables = rec {
      XDG_DATA_HOME = "\${HOME}/.local/share";
    };
    systemPackages = with pkgs; [
      # base
      cryptsetup
      wl-clipboard
      killall
      git
      vim_configurable
      firefox
      chromium

      # work
      gnumake
      go_1_18
      kubectl
      calc
      jq
    ];
  };
}
