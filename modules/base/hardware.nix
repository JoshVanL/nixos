{ lib, config, ... }:
with lib;
let
  cfg = config.me.base.hardware;

in {
  options.me.base.hardware = {
    zfsArcMaxBytes = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        Cap the ZFS ARC at this many bytes via the zfs.zfs_arc_max kernel
        parameter. When null, ZFS auto-tunes (typically ~50% of RAM).
      '';
    };
    zramSwapMemoryPercent = mkOption {
      type = types.int;
      default = 50;
      description = ''
        Percentage of RAM to reserve for zram-backed swap.
      '';
    };
  };

  config = {
    fileSystems = {
      "/" = {
        device = "rpool/local/root";
        fsType = "zfs";
      };

      "/boot" = {
        device = "/dev/disk/by-label/boot";
        fsType = "vfat";
      };

      "/nix" = {
        device = "rpool/local/nix";
        fsType = "zfs";
      };

      "/keep" = {
        device = "rpool/local/keep";
        fsType = "zfs";
        neededForBoot = true;
      };

      "/persist" = {
        device = "rpool/safe/persist";
        fsType = "zfs";
        neededForBoot = true;
      };
    };

    hardware.enableRedistributableFirmware = true;
    zramSwap.enable = true;
    zramSwap.memoryPercent = cfg.zramSwapMemoryPercent;

    boot.kernelParams = mkIf (cfg.zfsArcMaxBytes != null)
      [ "zfs.zfs_arc_max=${toString cfg.zfsArcMaxBytes}" ];

    services = {
      # ZFS maintenance settings.
      zfs = {
        autoScrub = {
          enable = true;
          pools  = [ "rpool" ];
        };
        trim.enable = true;
      };
    };
  };
}
