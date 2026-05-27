{ ... }:

{
  me = {
    machineName = "peach";
    system = "aarch64-linux";
    username = "josh";
    roles.assume = [ "josh" "nixsub" "dev" "img" ];
    base = {
      boot = {
        loader = "systemd-boot";
        initrd.availableKernelModules = [ "xhci_pci" "usbhid" "sr_mod" ];
        kernelParams = [ "transparent_hugepage=madvise" ];
      };
      parallels.enable = true;
      hardware = {
        zfsArcMaxBytes = 8 * 1024 * 1024 * 1024;
        zramSwapMemoryPercent = 50;
      };
      nix = {
        maxJobs = "auto";
        cores = 0;
      };
    };
    networking = {
      interfaces = [ "enp0s5" ];
      tailscale.vpn.enable = false;
    };
    window-manager = {
      enable = true;
      fontsize = 25;
      dpi = 255;
      xrandrArgs = ''
        --newmode 4096x2560_60 905.75 4096 4448 4896 5696 2560 2563 2569 2651 -HSync +VSync
        --addmode Virtual-1 4096x2560_60
        --output Virtual-1 --mode 4096x2560_60 --output Virtual-2 --off
      '';
      xMouseSpeedDeceleration = {
        enable = true;
        prop = 8;
        deceleration = 1.0;
      };
    };
  };

  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
    "vm.page-cluster" = 0;
  };
}
