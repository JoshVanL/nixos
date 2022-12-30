{ lib, pkgs, config, ... }:

{
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

    settings.trusted-users = [ "root" "josh" ];

    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
  system.stateVersion = "22.11";

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

  services.josh = {
    docker.enable = true;
    links.enable = true;
    tailscale.enable = true;
    yubikey.enable = true;
    i3 = {
      enable = true;
      xrandr = "--output Virtual-1 --mode 4096x2160 --output Virtual-2 --off";
    };
  };

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
