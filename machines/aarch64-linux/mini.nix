{ pkgs, lib, ... }: {
  me = {
    base = {
      username = "notme";
      boot = {
        loader = "systemd-boot";
        initrd.availableKernelModules = [ "xhci_pci" "usbhid" "sr_mod" ];
      };
      hardware.parallels.enable = true;
    };
    dev = {
      c.enable = true;
      go.enable = true;
      kube.enable = true;
      crypto.enable = true;
      data.enable = true;
      image.enable = true;
      python.enable = true;
    };
    networking = {
      ssh.enable = true;
      tailscale.enable = true;
      interfaces = {
        hostName = "mini";
        intf.enp0s5.useDHCP = true;
      };
    };
    programs = {
      git = {
        enable = true;
        username = "joshvanl";
        email = "me@joshvanl.dev";
      };
      google.enable = true;
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
      fontsize = 25;
      xrandrArgs = "--output Virtual-1 --mode 4096x2160 --rate 120 --output Virtual-2 --off";
    };
  };
}

