{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./hosts/host.nix
    ./modules
  ];

  # Nix.
  nix = {
    allowedUsers      = [ "root" "josh"];
    autoOptimiseStore = true;

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
  system.stateVersion = "nixos";

  # boot controlls.
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

  # Needed for config and user passwords.
  fileSystems."/persist".neededForBoot = true;
  fileSystems."/keep".neededForBoot = true;

  # Networking.
  networking = {
    networkmanager.enable = true;
    firewall.enable = false;
    wireless.userControlled.enable = false;
    useDHCP  = false;

    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };

  # ZFS maintenance settings.
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

  # Language.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  # Sound.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    jack.enable = true;
  };

  programs.zsh.enableCompletion = true;
  # Users.
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
        extraGroups = [
          "wheel"
          "networkmanager"
          "video"
          "docker"
        ];
        passwordFile = "/keep/etc/users/josh";
      };
      root = {
        hashedPassword = "!";
      };
    };
  };

  # Global env vars.
  environment.sessionVariables = rec {
    XDG_DATA_HOME = "\${HOME}/.local/share";
  };
}
