{ pkgs, lib, config, ... }: {
  me = {
    base = {
      username = "josh";
      nix = {
        substituters = [
          "http://nixcache.joshvanl.dev/"
          "http://machinecache.joshvanl.dev/"
        ];
        trusted-public-keys = config.me.security.joshvanl.nixPublicKeys;
      };
      boot = {
        loader = "systemd-boot";
        initrd.availableKernelModules = [ "ehci_pci" "nvme" "xhci_pci" "ahci" "usbhid" "sd_mod" ];
      };
      hardware.system = "x86_64-linux";
    };
    dev = {
      git = {
        enable = true;
        username = "joshvanl";
        email = "me@joshvanl.dev";
      };
      build.enable = true;
      go = {
        enable = true;
        proxy = "http://gocache.joshvanl.dev|https://proxy.golang.org";
      };
      kube.enable = true;
      crypto.enable = true;
      data.enable = true;
      image.enable = true;
      cloud.enable = true;
    };
    data = {
      zfs_uploader = {
        enable = true;
        logPath = "/keep/run/zfs_uploader/zfs_uploader.log";
        configPath = "/persist/etc/zfs_uploader/config.cfg";
      };
    };
    networking = {
      ssh.enable = true;
      tailscale.enable = true;
      interfaces = {
        hostName = "thistle";
        intf = {
          enp1s0.useDHCP = true;
          enp2s0f0.useDHCP = true;
          wlan0.useDHCP = true;
        };
      };
      podman = {
        enable = true;
        mirrorDomain = "containercache.joshvanl.dev";
        mirrors = [
          "docker.io"
          "ghcr.io"
          "quay.io"
          "registry.k8s.io"
          "mcr.microsoft.com"
        ];
      };
    };
    shell = {
      neovim = {
        enable = true;
        coPilot.enable = true;
        openAI = {
          enable = true;
          apiKeyPath = "/persist/home/secrets/chatgpt/api_key";
        };
      };
      zsh.enable = true;
    };
    security = {
      bitwarden.enable = true;
      yubikey.enable = true;
    };
    window-manager = {
      enable = true;
      fontsize = 10;
      xrandrArgs = "--output DP-1 --mode 3840x2160 --rate 120";
      naturalScrolling = true;
    };
  };
}