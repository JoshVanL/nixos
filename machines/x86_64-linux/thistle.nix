{ config, pkgs, lib, modulesPath, ... }: {

  boot = {
    initrd.availableKernelModules = [ "ehci_pci" "nvme" "xhci_pci" "ahci" "usbhid" "sd_mod" ];
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
    podman.enable = true;
    tailscale.enable = true;
    yubikey.enable = true;
    zfs_uploader = {
      enable = true;
      logPath = "/keep/etc/zfs_uploader/zfs_uploader.log";
      configPath = "/persist/etc/zfs_uploader/config.cfg";
    };
    dwm = {
      enable = true;
      xrandr = "--output DP-1 --mode 3840x2160 --rate 120";
    };
  };

  home-manager.users.josh = {
    gcloud.enable = true;
    dev-go.enable = true;
    dev-python.enable = true;
    dev-kube.enable = true;
  };

  services.xserver = {
    libinput = {
      enable = true;
    };
    extraConfig = ''
      Section "InputClass"
        Identifier "libinput pointer catchall"
        MatchDevicePath "/dev/input/event*"
        Driver "libinput"
        Option "NaturalScrolling" "true"
      EndSection
    '';
  };

  environment.systemPackages = with pkgs; [
  ];
}
