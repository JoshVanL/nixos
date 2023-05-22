{ pkgs, lib, config, ... }: {
  me = {
    username = "josh";
    system = "aarch64-linux";
    base = {
      nix = {
        substituters = [ "http://nixcache.joshvanl.dev" ];
        gc.automatic = false;
      };
      boot = {
        loader = "raspberrypi";
        kernelPackages = pkgs.linuxPackages_rpi4;
        # ttyAMA0 is the serial console broken out to the GPIO
        kernelParams = [
          "nohibernate"
          "8250.nr_uarts=1"
          "console=ttyAMA0,115200"
          "console=tty1"
        ];
        initrd = {
          availableKernelModules = [ "usbhid" "usb_storage" "smsc95xx" "usbnet" ];
          ssh = {
            enable = true;
            authorizedKeys = config.me.security.joshvanl.sshPublicKeys;
          };
        };
        # Enable so we can build other machines for the cache.
        emulatedSystems = [ "x86_64-linux" ];
      };
    };
    data = {
      cache = {
        nix = {
          enable = true;
          domain = "nixcache.joshvanl.dev";
          cacheDir = "/keep/run/nginx/cache/nix";
          maxCacheSize = "300G";
          maxCacheAge = "180d";
        };
        machine = {
          enable = true;
          domain = "machinecache.joshvanl.dev";
          secretKeyFile = "/persist/etc/joshvanl/machinecache/cache-priv-key.pem";
          machineRepo = "https://github.com/joshvanl/nixos";
          timerOnCalendar = "*-*-* 4:00:00";
        };
        go = {
          enable = true;
          domain = "gocache.joshvanl.dev";
        };
        container = {
          enable = true;
          domain = "containercache.joshvanl.dev";
          registries = [
            {name = "docker.io"; upstream = "registry-1.docker.io";}
            "ghcr.io"
            "quay.io"
            "registry.k8s.io"
            "mcr.microsoft.com"
          ];
        };
      };
      zfs_uploader = {
        enable = true;
        logPath = "/keep/run/zfs_uploader/zfs_uploader.log";
        configPath = "/persist/etc/zfs_uploader/config.cfg";
      };
    };
    networking = {
      interfaces = {
        hostName = "burgundy";
        intf = {
          eth0.useDHCP  = true;
          wlan0.useDHCP = false;
        };
      };
      ssh = {
        enable = true;
        ingress = {
          enable = true;
          authorizedKeys = config.me.security.joshvanl.sshPublicKeys;
        };
      };
      tailscale = {
        enable = true;
        ingress.enable = true;
      };
      acme = {
        enable = true;
        dnsProvider = "gcloud";
        email = "me@joshvanl.dev";
        credentialsFile = "/persist/etc/joshvanl/dns/acme/credentials.secret";
      };
    };
    dev.git.enable = true;
    shell = {
      neovim.enable = true;
      zsh.enable = true;
    };
    security = {
      bitwarden = {
        enable = true;
        server = {
          enable = true;
          domain = "bitwarden.joshvanl.dev";
        };
      };
      yubikey = {
        enable = true;
        pam = {
          enable = true;
          authorizedIDs = config.me.security.joshvanl.yubikeyIDs;
        };
      };
    };
  };
}
