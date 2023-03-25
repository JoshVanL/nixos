{ pkgs, lib, ... }: {

  # Move as option.
  boot = {
    initrd.availableKernelModules = [ "ehci_pci" "nvme" "xhci_pci" "ahci" "usbhid" "sd_mod" ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  # Move to option.
  networking = {
    hostName = "thistle";
    hostId = "deadbeef";
    interfaces = {
      enp1s0.useDHCP = true;
      enp2s0f0.useDHCP = true;
      wlp3s0.useDHCP = true;
    };
  };

  me = {
    username = "josh";
    dev = {
      c.enable = true;
      go.enable = true;
      python.enable = true;
      kube.enable = true;
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
        openaiAPIKeyPath = "/persist/home/secrets/chatgpt/api_key";
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
      fontsize = 8;
      xrandr = "--output DP-1 --mode 3840x2160 --rate 120";
    };
  };

  # TODO: move to window-manager
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
}
