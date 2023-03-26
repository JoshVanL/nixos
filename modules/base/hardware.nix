{ lib, config, ... }:

with lib;
let
  cfg = config.me.base.hardware;

in {
  options.me.base.hardware = {
    parallels.enable = mkEnableOption "Parallels Desktop";
  };

  config = {
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
    hardware = {
      video.hidpi.enable = true;
      enableRedistributableFirmware = true;
      parallels.enable = cfg.parallels.enable;
    };
    nixpkgs.config.allowUnfreePredicate = mkIf cfg.parallels.enable
      (pkg: builtins.elem (lib.getName pkg) [ "prl-tools" ]);

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
  };
}
