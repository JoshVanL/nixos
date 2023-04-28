{ pkgs, lib, ... }: {
  me = {
    base = {
      username = "josh";
      boot = {
        loader = "systemd-boot";
        initrd.availableKernelModules = [ "xhci_pci" "usbhid" "sr_mod" ];
      };
      nix.substituters = [
        "http://cache.joshvanl.dev/"
        "http://cache.nixos.org/"
      ];
      hardware.parallels.enable = true;
    };
    dev = {
      build.enable = true;
      c.enable = true;
      cloud.enable = true;
      crypto.enable = true;
      go.enable = true;
      kube.enable = true;
      data.enable = true;
      image.enable = true;
      python.enable = true;
    };
    data = {
      zfs_uploader = {
        enable = true;
        logPath = "/keep/var/run/zfs_uploader/zfs_uploader.log";
        configPath = "/persist/etc/zfs_uploader/config.cfg";
      };
    };
    networking = {
      ssh.enable = true;
      tailscale.enable = true;
      interfaces = {
        hostName = "purple";
        intf.enp0s5.useDHCP = true;
      };
    };
    programs = {
      git = {
        enable = true;
        username = "joshvanl";
        email = "me@joshvanl.dev";
      };
      neovim = {
        enable = true;
        coPilot.enable = true;
      };
      podman.enable = true;
      zsh.enable = true;
    };
    security = {
      bitwarden.enable = true;
      yubikey.enable = true;
    };
    window-manager = {
      enable = true;
      fontsize = 15;
      xrandrArgs = "--output Virtual-1 --mode 4096x2160 --rate 120 --output Virtual-2 --off";
    };
  };
}

