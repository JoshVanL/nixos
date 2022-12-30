{ config, pkgs, lib, modulesPath, ... }: {

  boot = {
    initrd.availableKernelModules = [ "xhci_pci" "usbhid" "sr_mod" ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    interfaces.enp0s5.useDHCP = true;
    hostName = "orange";
    hostId = "deadbeef";
  };

  nixpkgs.config = {
    allowUnsupportedSystem = true;
  };
}
