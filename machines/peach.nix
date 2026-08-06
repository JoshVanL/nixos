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

  # Disk-backed spillover for zram, on a second 64G Parallels virtual disk.
  # zram alone has no overflow, so when it fills the machine goes straight from
  # fine to global OOM kill.
  #
  # Recreating this from scratch (fresh install, new host, or a deleted disk
  # image) takes two manual steps, since nothing here provisions it:
  #
  #   1. Parallels > Configure > Hardware > + > Hard Disk. 64G, expanding is
  #      fine, it only ever holds swap. Do not let Parallels format it.
  #   2. Give it a GPT with one named partition covering the whole disk:
  #
  #        sudo sfdisk /dev/disk/by-id/<the-new-disk> <<'EOF'
  #        label: gpt
  #        name=peach-swap, type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F
  #        EOF
  #
  # No mkswap: randomEncryption runs cryptsetup and mkswap on every boot.
  swapDevices = [{
    device = "/dev/disk/by-partlabel/peach-swap";
    # rpool is aes-256-gcm encrypted. Without this, anything paged out lands on
    # disk in plaintext and undoes that. Random key is regenerated each boot.
    randomEncryption = {
      enable = true;
      # Expanding disk on the host, so pass TRIM through and let freed swap
      # shrink the image back. Leaks which blocks are unused, which means
      # nothing for a device re-keyed every boot.
      allowDiscards = true;
    };
    # zram is priority 5. Lower priority here means zram absorbs the hot path
    # and the disk only takes the overflow.
    priority = 1;
  }];

  specialisation = {
    diagrid-dev = {
      inheritParentConfig = true;
      configuration = {
        me.dev.diagrid.enable = true;
      };
    };
  };
}
