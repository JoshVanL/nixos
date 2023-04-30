{ pkgs, lib, config, ... }: {
  me = {
    base = {
      username = "josh";
      nix = {
        substituters = [
          "https://nixcache.joshvanl.dev/"
        ];
        trusted-public-keys = config.me.security.joshvanl.nixPublicKeys;
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
      };
    };
    data = {
      nixcache = {
        enable = true;
        domain = "nixcache.joshvanl.dev";
        cacheDir = "/keep/var/run/nginx/cache/nix";
        maxCacheSize = "50G";
        maxCacheAge = "90d";
      };
      machinecache = {
        enable = true;
        domain = "machinecache.joshvanl.dev";
        secretKeyFile = "/persist/etc/joshvanl/machinecache/cache-priv-key.pem";
        machineRepo = "https://github.com/joshvanl/nixos";
        timerOnCalendar = "*-*-* 4:00:00";
      };
      zfs_uploader = {
        enable = true;
        logPath = "/keep/var/run/zfs_uploader/zfs_uploader.log";
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
    programs = {
      git.enable = true;
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
