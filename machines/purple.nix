{ pkgs, lib, config, ... }:

let
  wireguardCfg = {
    enable = true;
    privateKeyFile = "/persist/etc/wireguard/private_key";
  } // config.me.security.joshvanl.wireguard;

in {
  me = {
    machineName = "purple";
    system = "aarch64-linux";
    username = "josh";
    base = {
      boot = {
        loader = "systemd-boot";
        initrd.availableKernelModules = [ "xhci_pci" "usbhid" "sr_mod" ];
      };
      nix = {
        extraSubstituters = [
          "http://nixcache.joshvanl.dev/"
          "http://machinecache.joshvanl.dev/"
        ];
        trusted-public-keys = config.me.security.joshvanl.nixPublicKeys;
      };
      parallels.enable = true;
    };
    dev = {
      git = {
        enable = true;
        username = "joshvanl";
        email = "me@joshvanl.dev";
      };
      build.enable = true;
      c.enable = true;
      cloud.enable = true;
      crypto.enable = true;
      go = {
        enable = true;
        extraProxies = ["http://gocache.joshvanl.dev"];
      };
      grpc.enable = true;
      kube.enable = true;
      data.enable = true;
      image.enable = true;
      python.enable = true;
      rust.enable = true;
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
      interfaces.intf.enp0s5.useDHCP = true;
      podman.enable = true;
    };
    shell = {
      neovim = {
        enable = true;
        coPilot.enable = true;
      };
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

  specialisation = {
    vpn = {
      inheritParentConfig = true;
      configuration = {
        me.networking.wireguard = wireguardCfg;
      };
    };
    onthemove = {
      inheritParentConfig = true;
      configuration = {
        me.networking.wireguard = wireguardCfg;
        me.window-manager.fontsize = lib.mkForce 24;
      };
    };
  };
}
