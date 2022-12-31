{ config, pkgs, lib, modulesPath, ... }: {

  boot = {
    initrd.availableKernelModules = [ "xhci_pci" "usbhid" "sr_mod" ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    hostName = "thistle";
    hostId = "deadbeef";
    interfaces = {
      enp1s0.useDHCP = true;
      enp2s0f0.useDHCP = true;
      wlp3s0.useDHCP = true;
    };
  };

  services.josh = {
    docker.enable = true;
    tailscale.enable = true;
    yubikey.enable = true;
    i3 = {
      enable = true;
      xrandr = "--output Virtual-1 --mode 4096x2160 --output Virtual-2 --off";
    };
  };

  environment.systemPackages = with pkgs; [
    tex
    lmodern
  ];
}
