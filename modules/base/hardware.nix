{ lib, config, ... }:

with lib;
let
  cfg = config.me.base.hardware;

in {
  options.me.base.hardware = {
    system = mkOption {
      type = types.str;
      default = "";
      description = "The architecture and OS of the system to install to.";
    };
    parallels.enable = mkEnableOption "Parallels Desktop";
  };

  config = {
    assertions = [{
      assertion = cfg.system == "x86_64-linux" || cfg.system == "aarch64-linux";
      message = "Invalid system: ${cfg.system}. Must be 'x86_64-linux' or 'aarch64-linux'.";
    }];

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

    swapDevices = [ ];

    # high-resolution display
    hardware = {
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
