{ lib, ... }: {
  me = {
    machineName = "mini";
    username = "notme";
    system = "aarch64-linux";
    base = {
      boot = {
        loader = "systemd-boot";
        initrd.availableKernelModules = [ "xhci_pci" "usbhid" "sr_mod" ];
      };
      parallels.enable = true;
    };
    networking = {
      interfaces.intf.enp0s5.useDHCP = true;
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
      fontsize = 32;
      xrandrArgs = "--output Virtual-1 --mode 4096x2160 --rate 120 --output Virtual-2 --off";
    };
  };
}

