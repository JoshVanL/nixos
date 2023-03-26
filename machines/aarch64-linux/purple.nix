{ pkgs, lib, ... }: {
  me = {
    base = {
      username = "josh";
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
    data = {
      # TODO:
      zfs_uploader = {
        enable = false;
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
      google.enable = true;
      neovim = {
        enable = true;
        coPilot.enable = true;
        openAI = {
          enable = true;
          apiKeyPath = "/persist/home/secrets/chatgpt/api_key";
        };
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

