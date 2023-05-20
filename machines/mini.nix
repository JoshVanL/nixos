{ lib, ... }: {
  me = {
    base = {
      username = "notme";
      boot = {
        loader = "systemd-boot";
        initrd.availableKernelModules = [ "xhci_pci" "usbhid" "sr_mod" ];
      };
      hardware.parallels.enable = true;
      hardware.system = "aarch64-linux";
    };
    networking = {
      interfaces = {
        hostName = "mini";
        intf.enp0s5.useDHCP = true;
      };
    };
    dev.git = {
      enable = true;
      username = "joshvanl";
      email = "me@joshvanl.dev";
    };
    shell = {
      neovim.enable = true;
      zsh.enable = true;
    };
    window-manager = {
      enable = true;
      fontsize = 25;
      xrandrArgs = "--output Virtual-1 --mode 4096x2160 --rate 120 --output Virtual-2 --off";
    };
  };
}

