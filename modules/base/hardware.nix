{ lib, config, ... }:
with lib;

{
  config = {
    fileSystems = {
      "/" = {
        device = "rpool/local/root";
        fsType = "zfs";
        neededForBoot = true;
        options = [ "zfsutil" ];
      };

      "/boot" = {
        device = "/dev/disk/by-label/boot";
        fsType = "vfat";
      };

      "/nix" = {
        device = "rpool/local/nix";
        fsType = "zfs";
        neededForBoot = true;
        options = [ "zfsutil" ];
      };

      "/keep" = {
        device = "rpool/local/keep";
        fsType = "zfs";
        neededForBoot = true;
        options = [ "zfsutil" ];
      };

      "/persist" = {
        device = "rpool/safe/persist";
        fsType = "zfs";
        neededForBoot = true;
        options = [ "zfsutil" ];
      };
    };

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
  };
}
