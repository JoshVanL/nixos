{ lib, ... }: {
  fileSystems."/" =
    { device = "rpool/local/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };

  fileSystems."/nix" =
    { device = "rpool/local/nix";
      fsType = "zfs";
    };

  fileSystems."/keep" =
    { device = "rpool/local/keep";
      fsType = "zfs";
      neededForBoot = true;
    };

  fileSystems."/persist" =
    { device = "rpool/safe/persist";
      fsType = "zfs";
      neededForBoot = true;
    };

  swapDevices = [ ];

  # high-resolution display
  hardware.video.hidpi.enable = lib.mkDefault true;

  hardware.enableRedistributableFirmware = true;

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
  };
}
