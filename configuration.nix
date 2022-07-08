{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./hosts/host.nix
    ./modules
  ];

  # Nix.
  nix = {
    settings = {
      allowed-users       = [ "root" "josh"];
      auto-optimise-store = true;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    extraOptions = ''
      experimental-features = nix-command
    '';
  };
  system.stateVersion = "22.11";

  # boot controlls.
  boot  = {
    # Clense with fire.
    initrd.postDeviceCommands = lib.mkAfter ''
      zfs rollback -r rpool/local/root@blank
    '';
    zfs = {
      requestEncryptionCredentials = true;
    };

    kernelParams         = [ "nohibernate" ];
    supportedFilesystems = [ "vfat" "zfs" ];
  };

  # Needed for config and user passwords.
  fileSystems = {
    "/persist".neededForBoot = true;
    "/keep".neededForBoot    = true;
  };

  # Networking.
  networking = {
    networkmanager.enable = true;
    wireless.userControlled.enable = false;
    useDHCP  = false;
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };

  services = {
    # ZFS maintenance settings.
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
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      jack.enable = true;
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
}
