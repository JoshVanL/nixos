{ lib, ... }: {
  me = {
    machineName = "mini";
    username = "notme";
    system = "aarch64-linux";
    roles.assume = [ "josh" "dev" ];
    base = {
      boot = {
        loader = "systemd-boot";
        initrd.availableKernelModules = [ "xhci_pci" "usbhid" "sr_mod" ];
      };
      parallels.enable = true;
    };
    networking.interfaces = ["enp0s5"];
    window-manager = {
      enable = true;
      fontsize = 32;
      xrandrArgs = "--output Virtual-1 --mode 4096x2160 --rate 120 --output Virtual-2 --off";
    };
  };
}

