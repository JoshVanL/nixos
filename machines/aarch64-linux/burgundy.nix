{ config, pkgs, lib, ... }:

let
  authorizedKeys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8f6d0e0AsHrOvImhh1HsFczFRX5grwrFN1b4Bq0ZCq0kn/e/mBJD66BwXLQa5/emeP66YXP975+pquIJ463rGfoZuNR9ocD6V+uQkuqr8axm8bBiSqwqIVrzoPAl6Uk5QrNtGztTdv/iULq45qrgSF4EIa+ZvvoggwmPhzI6XFboheUuGTW9ktS3/Fa6Jmlz7pYvK4RNRhxpNMpCkjG2jYpVzLsiZhqiLK6Wk+cyGZ3FZx5lNQgBDUoR1Nzfmb21NC8MYapmTl0eCSH9asOMuGBGlgSFNhLsZhvMYCXB6GZ/lDn70J37XTtRcirHoXEDfePcE/pYLP3/rNjv1UA39"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCaBFpBKuTdsanEImU0BhICRbw9U6V3zCtgksyEhZv65iYEoTrxtRH6BIcMB7onSLjgNj+do+vaQH+yXGrmZc1zfWIynso4vzaZpqNgthIbXaXR3iwRh6FyE9PQx4iOgNVv3DznKZMdVhrlW9NliWHxFv27saUOqLefm9qdIhWWfgrl8y4JxRCTPKIFonIqU2dg4EZXXqJJlEQNU9lkOybncQSfH4zykrJYRIJ/XHMUxQEXO02tqdSqSuhVhv1fxAfF33o+HBhASN50uWB2qh3gHb95pqWm3nQa9OLk66YffviWkURxhXhiCdv5A9aOsCvUTEg/PQrVeJFAu4VMNtJR"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDeppp8Ozc2Fzbe9SwWu6lcC7y4Fh0bRBIO9sMqXRWuOToV/IDLq9gcF9Qx/X48sQOETMJHpYK8aQgAoDuJPGutmWpJf8OyfkGtnc1pwpaAtwwfXzc91uUwRP7MevseRiu3tOVZdXS39xNUbEqJgXLhZVb+Ai+CBDQ7t1vyZ3KwtxGIXTc+BCPuQZ/GKdzxFzdVgaDKLChEJaecYNkzqSZ2ZnF9qwG/4RowEwyKDFDvRqXUEGEZAcYlJ2KDQQvk94MsNhFWRHFNGKYpTcbL69WxSXZQariiASjU1oWzCwQYPtd05TX0F7IkFk80jyp8HM9cM6J3iDF6xrOycLS7m4RgojKTpBTBDCpyaUrWN7PfSVIMQE/KGKIlnr4RT2ewubmPSWqS4ohWF7pZx6MrpQIRynMl8GxXTUy1nnlAPFrqnre0Qahg+5E3Id36f+5yi+kM0C4N7KIzR5cXT+gGCMcmXqtjTowOLDRpwZ9UuiEN4wjey+7OfGUdLW2AU/wsZo5kQ0IrvjQnZVAQVVHViDxTv8FlIdII2wVc/AgOdnTbgS4t5pxf+/XD6flVRpAdRb5pttC0iYnXfh2gueUG546qgsXoHAxo7ymT/zbLe8lmN2zwiZlkwVQ47RWYPtgWvuP2/4ebQ584nGq1hPzx1RKrOdSNZODd/wRjPytD6k5J/w=="
    # navy
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAINJi8FX/b+2qsAeEN8KfTe7rP1+bCXvmZ/oxyhcAcvTVAAAABHNzaDo="
    # gold-fido
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIFOiIRyDiW99jt4klbFBwWYaUDbt9x33vab+lummvaA2AAAABHNzaDo="
  ];
in {
  boot = {
    kernelPackages = pkgs.linuxPackages_rpi4;
    initrd = {
      availableKernelModules = [ "usbhid" "usb_storage" "smsc95xx" "usbnet" ];

      network = {
        enable = true;
        ssh = {
          enable = true;
          port = 22;
          ignoreEmptyHostKeys = true;
          authorizedKeys = authorizedKeys;
        };
        # we use step-cli to generate the ssh keys here since ssh-keygen has a
        # wobly about non-existent users.
        postCommands = ''
          mkdir -p /etc/ssh/
          ${pkgs.step-cli}/bin/step crypto keypair -f --kty=OKP --crv=Ed25519 --no-password --insecure /etc/ssh/pub /etc/ssh/priv
          ${pkgs.step-cli}/bin/step crypto key format -f --no-password --insecure --ssh --out /etc/ssh/ssh_host_ed25519_key /etc/ssh/priv
          ${pkgs.step-cli}/bin/step crypto key format -f --no-password --insecure --ssh --out /etc/ssh/ssh_host_ed25519_key.pub /etc/ssh/pub
          echo "zfs load-key -a; killall zfs" >> /root/.profile
        '';
      };

    };
    # ttyAMA0 is the serial console broken out to the GPIO
    kernelParams = [
      "nohibernate"
      "8250.nr_uarts=1"
      "console=ttyAMA0,115200"
      "console=tty1"
    ];
    loader = {
      efi.canTouchEfiVariables = true;
      grub.enable = false;
      raspberryPi = {
        enable = true;
        version = 4;
      };
    };
  };

  networking = {
    hostName = "burgundy";
    hostId = "deadbeef";
    interfaces = {
      eth0.useDHCP  = true;
      wlan0.useDHCP = false;
    };

    # VPN using tailscale (good software).
    firewall = {
      enable = true;
      trustedInterfaces = [ "tailscale0" ];
      # allow the Tailscale UDP port through the firewall
      allowedUDPPorts = [ config.services.tailscale.port ];
      # allow you to SSH in over the public internet
      allowedTCPPorts = [ 22 ];
    };
  };

  nixpkgs.config = {
    allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "prl-tools" ];
    allowUnsupportedSystem = true;
  };

  users.users.josh.openssh.authorizedKeys.keys = authorizedKeys;

  home-manager.users.josh = { pkgs, ... }: {
    pam.yubico.authorizedYubiKeys.ids = [ "cccccbegbgvj" "cccccclbfjcf" ];
  };

  security = {
    pam.yubico = { enable = true; id = "16"; };
    acme = {
      acceptTerms = true;
      defaults = {
        email = "me@joshvanl.dev";
        dnsProvider = "gcloud";
        credentialsFile = "/persist/etc/joshvanl/dns/acme/credentials.secret";
      };
    };
  };

  services = {
    josh = {
      tailscale.enable = true;
      yubikey.enable = true;
      zfs_uploader = {
        enable = true;
        logPath = "/keep/etc/zfs_uploader/zfs_uploader.log";
        configPath = "/persist/etc/zfs_uploader/config.cfg";
      };
    };
    openssh = {
      enable = true;
      settings = {
        passwordAuthentication = false;
        kbdInteractiveAuthentication = true;
      };
    };
    vaultwarden = {
      enable = true;
      dbBackend = "postgresql";
      config = {
        tz = "Europe/London";
        domain = "https://bitwarden.joshvanl.dev";
        signupsAllowed = false;
        invitationsAllowed = false;
        rocketPort = 8222;
        databaseUrl = "postgresql://vaultwarden@%2Frun%2Fpostgresql/vaultwarden";
        enableDbWal = "false";
      };
    };
    postgresql = {
      enable = true;
      package        = pkgs.postgresql_14;
      authentication = lib.mkForce ''
        # TYPE  DATABASE        USER            ADDRESS                 METHOD
        local   all             all                                     trust
        host    all             all             127.0.0.1/32            trust
        host    all             all             ::1/128                 trust
      '';
      initialScript = pkgs.writeText "backend-initScript" ''
        CREATE ROLE vaultwarden WITH LOGIN PASSWORD 'vaultwarden' CREATEDB;
        CREATE DATABASE vaultwarden;
        GRANT ALL PRIVILEGES ON DATABASE vaultwarden TO vaultwarden;
      '';
      ensureDatabases = ["vaultwarden"];
      ensureUsers = [
       {
         name = "vaultwarden";
         ensurePermissions = {
           "DATABASE vaultwarden" = "ALL PRIVILEGES";
         };
       }
      ];
    };
    postgresqlBackup = {
      enable = true;
      databases = [ "vaultwarden" ];
    };
    nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;

      virtualHosts = {
        "bitwarden.joshvanl.dev" = {
          forceSSL = true;
          enableACME = true;
          acmeRoot = null;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8222";
            proxyWebsockets = true;
          };
          extraConfig = ''
            proxy_read_timeout 90;
            add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
            add_header X-Content-Type-Options nosniff;
            add_header X-XSS-Protection "1; mode=block";
            add_header X-Frame-Options SAMEORIGIN;
          '';
        };
      };
    };
  };

  systemd = {
    services = {
      postgresql.after = [ "systemd-tmpfiles-setup.service" ];
      nginx.after = [ "systemd-tmpfiles-setup.service" ];
      vaultwarden = {
        wants = [ "nginx.service" ];
        after = ["systemd-tmpfiles-setup.service"  "nginx.service" ];
        bindsTo = [ "nginx.service" ];
      };
    };
    tmpfiles.rules = [
      "d /persist/var/lib/postgresql   0755 josh wheel - -"
      "d /persist/var/lib/bitwarden_rs 0755 vaultwarden vaultwarden - -"
      "d /persist/var/lib/acme         0755 acme acme - -"
    ];
  };
  fileSystems = {
    "/var/lib/postgresql" = { options = [ "bind" ]; device = "/persist/var/lib/postgresql"; };
    "/var/lib/bitwarden_rs" = { options = [ "bind" ]; device = "/persist/var/lib/bitwarden_rs"; };
    "/var/lib/acme" = { options = [ "bind" ]; device = "/persist/var/lib/acme"; };
  };
}
