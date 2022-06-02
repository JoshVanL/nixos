{ lib, pkgs, config, ... }:

let
  joshvanlPath = "/persist/etc/joshvanl";
  joshvanlDNSPath = "${joshvanlPath}/dns";
  dnsBitwarden = if builtins.pathExists "${joshvanlDNSPath}/domains/bitwarden"
  then (builtins.readFile "${joshvanlDNSPath}/domains/bitwarden")
    else "null"
  ;
  acmeEmail = if builtins.pathExists "${joshvanlDNSPath}/acme/email"
    then (builtins.readFile "${joshvanlDNSPath}/acme/email")
    else "null@null.com"
  ;
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
          hostKeys = [ /persist/etc/ssh/initrd_host_ed_25519_key ];
          authorizedKeys = [
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8f6d0e0AsHrOvImhh1HsFczFRX5grwrFN1b4Bq0ZCq0kn/e/mBJD66BwXLQa5/emeP66YXP975+pquIJ463rGfoZuNR9ocD6V+uQkuqr8axm8bBiSqwqIVrzoPAl6Uk5QrNtGztTdv/iULq45qrgSF4EIa+ZvvoggwmPhzI6XFboheUuGTW9ktS3/Fa6Jmlz7pYvK4RNRhxpNMpCkjG2jYpVzLsiZhqiLK6Wk+cyGZ3FZx5lNQgBDUoR1Nzfmb21NC8MYapmTl0eCSH9asOMuGBGlgSFNhLsZhvMYCXB6GZ/lDn70J37XTtRcirHoXEDfePcE/pYLP3/rNjv1UA39"
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCaBFpBKuTdsanEImU0BhICRbw9U6V3zCtgksyEhZv65iYEoTrxtRH6BIcMB7onSLjgNj+do+vaQH+yXGrmZc1zfWIynso4vzaZpqNgthIbXaXR3iwRh6FyE9PQx4iOgNVv3DznKZMdVhrlW9NliWHxFv27saUOqLefm9qdIhWWfgrl8y4JxRCTPKIFonIqU2dg4EZXXqJJlEQNU9lkOybncQSfH4zykrJYRIJ/XHMUxQEXO02tqdSqSuhVhv1fxAfF33o+HBhASN50uWB2qh3gHb95pqWm3nQa9OLk66YffviWkURxhXhiCdv5A9aOsCvUTEg/PQrVeJFAu4VMNtJR"
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDeppp8Ozc2Fzbe9SwWu6lcC7y4Fh0bRBIO9sMqXRWuOToV/IDLq9gcF9Qx/X48sQOETMJHpYK8aQgAoDuJPGutmWpJf8OyfkGtnc1pwpaAtwwfXzc91uUwRP7MevseRiu3tOVZdXS39xNUbEqJgXLhZVb+Ai+CBDQ7t1vyZ3KwtxGIXTc+BCPuQZ/GKdzxFzdVgaDKLChEJaecYNkzqSZ2ZnF9qwG/4RowEwyKDFDvRqXUEGEZAcYlJ2KDQQvk94MsNhFWRHFNGKYpTcbL69WxSXZQariiASjU1oWzCwQYPtd05TX0F7IkFk80jyp8HM9cM6J3iDF6xrOycLS7m4RgojKTpBTBDCpyaUrWN7PfSVIMQE/KGKIlnr4RT2ewubmPSWqS4ohWF7pZx6MrpQIRynMl8GxXTUy1nnlAPFrqnre0Qahg+5E3Id36f+5yi+kM0C4N7KIzR5cXT+gGCMcmXqtjTowOLDRpwZ9UuiEN4wjey+7OfGUdLW2AU/wsZo5kQ0IrvjQnZVAQVVHViDxTv8FlIdII2wVc/AgOdnTbgS4t5pxf+/XD6flVRpAdRb5pttC0iYnXfh2gueUG546qgsXoHAxo7ymT/zbLe8lmN2zwiZlkwVQ47RWYPtgWvuP2/4ebQ584nGq1hPzx1RKrOdSNZODd/wRjPytD6k5J/w=="
          ];
        };
        postCommands = ''
          echo "zfs load-key -a; killall zfs" >> /root/.profile
        '';
      };
    };
    # ttyAMA0 is the serial console broken out to the GPIO
    kernelParams = [
        "8250.nr_uarts=1"
        "console=ttyAMA0,115200"
        "console=tty1"
        # A lot GUI programs need this, nearly all wayland applications
        "cma=128M"
    ];
    loader.raspberryPi = {
      enable = true;
      version = 4;
    };
    loader.grub.enable = false;
  };

  nixpkgs.config.allowUnsupportedSystem = true;

  networking = {
    hostName = "burgundy";
    hostId   = "414d6053";
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
      checkReversePath = "loose";
    };
  };

  environment.etc = {
    "joshvanl/window-manager/kanshi.cfg" = {
      text = ''
        { }
      '';
      mode = "644";
    };
  };

  users.users.josh.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8f6d0e0AsHrOvImhh1HsFczFRX5grwrFN1b4Bq0ZCq0kn/e/mBJD66BwXLQa5/emeP66YXP975+pquIJ463rGfoZuNR9ocD6V+uQkuqr8axm8bBiSqwqIVrzoPAl6Uk5QrNtGztTdv/iULq45qrgSF4EIa+ZvvoggwmPhzI6XFboheUuGTW9ktS3/Fa6Jmlz7pYvK4RNRhxpNMpCkjG2jYpVzLsiZhqiLK6Wk+cyGZ3FZx5lNQgBDUoR1Nzfmb21NC8MYapmTl0eCSH9asOMuGBGlgSFNhLsZhvMYCXB6GZ/lDn70J37XTtRcirHoXEDfePcE/pYLP3/rNjv1UA39"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCaBFpBKuTdsanEImU0BhICRbw9U6V3zCtgksyEhZv65iYEoTrxtRH6BIcMB7onSLjgNj+do+vaQH+yXGrmZc1zfWIynso4vzaZpqNgthIbXaXR3iwRh6FyE9PQx4iOgNVv3DznKZMdVhrlW9NliWHxFv27saUOqLefm9qdIhWWfgrl8y4JxRCTPKIFonIqU2dg4EZXXqJJlEQNU9lkOybncQSfH4zykrJYRIJ/XHMUxQEXO02tqdSqSuhVhv1fxAfF33o+HBhASN50uWB2qh3gHb95pqWm3nQa9OLk66YffviWkURxhXhiCdv5A9aOsCvUTEg/PQrVeJFAu4VMNtJR"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDeppp8Ozc2Fzbe9SwWu6lcC7y4Fh0bRBIO9sMqXRWuOToV/IDLq9gcF9Qx/X48sQOETMJHpYK8aQgAoDuJPGutmWpJf8OyfkGtnc1pwpaAtwwfXzc91uUwRP7MevseRiu3tOVZdXS39xNUbEqJgXLhZVb+Ai+CBDQ7t1vyZ3KwtxGIXTc+BCPuQZ/GKdzxFzdVgaDKLChEJaecYNkzqSZ2ZnF9qwG/4RowEwyKDFDvRqXUEGEZAcYlJ2KDQQvk94MsNhFWRHFNGKYpTcbL69WxSXZQariiASjU1oWzCwQYPtd05TX0F7IkFk80jyp8HM9cM6J3iDF6xrOycLS7m4RgojKTpBTBDCpyaUrWN7PfSVIMQE/KGKIlnr4RT2ewubmPSWqS4ohWF7pZx6MrpQIRynMl8GxXTUy1nnlAPFrqnre0Qahg+5E3Id36f+5yi+kM0C4N7KIzR5cXT+gGCMcmXqtjTowOLDRpwZ9UuiEN4wjey+7OfGUdLW2AU/wsZo5kQ0IrvjQnZVAQVVHViDxTv8FlIdII2wVc/AgOdnTbgS4t5pxf+/XD6flVRpAdRb5pttC0iYnXfh2gueUG546qgsXoHAxo7ymT/zbLe8lmN2zwiZlkwVQ47RWYPtgWvuP2/4ebQ584nGq1hPzx1RKrOdSNZODd/wRjPytD6k5J/w=="
  ];

  home-manager.users.josh = { pkgs, ... }: {
    pam.yubico.authorizedYubiKeys.ids = [ ]
    ++ lib.optional (builtins.pathExists "${joshvanlPath}/yubikey/otp-client-id-1") (builtins.readFile "${joshvanlPath}/yubikey/otp-client-id-1")
    ++ lib.optional (builtins.pathExists "${joshvanlPath}/yubikey/otp-client-id-2") (builtins.readFile "${joshvanlPath}/yubikey/otp-client-id-2")
    ;
  };

  security = {
    pam.yubico = { enable = true; id = "16"; };
    acme = {
      acceptTerms = true;
      defaults = {
        email = "${acmeEmail}";
        dnsProvider = "gcloud";
        credentialsFile = "${joshvanlDNSPath}/acme/credentials.secret";
      };
    };
  };

  services = {
    openssh = {
      enable = true;
      passwordAuthentication = false;
      kbdInteractiveAuthentication = true;
    };
    vaultwarden = {
      enable = true;
      dbBackend = "postgresql";
      config = {
        tz                 = "Europe/London";
        domain             = "https://${dnsBitwarden}";
        signupsAllowed     = false;
        invitationsAllowed = false;
        rocketPort         = 8222;
        databaseUrl        = "postgresql://vaultwarden@%2Frun%2Fpostgresql/vaultwarden";
        enableDbWal        = "false";
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
      ensureUsers     = [
       {
         name = "vaultwarden";
         ensurePermissions = {
           "DATABASE vaultwarden" = "ALL PRIVILEGES";
         };
       }
      ];
    };
    postgresqlBackup = {
      enable    = true;
      databases = [ "vaultwarden" ];
    };
    nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedGzipSettings  = true;
      recommendedOptimisation  = true;
      recommendedTlsSettings   = true;

      virtualHosts = {
        "${dnsBitwarden}" = {
          forceSSL   = true;
          enableACME = true;
          acmeRoot   = null;
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
      nginx.after      = [ "systemd-tmpfiles-setup.service" ];
      vaultwarden = {
        wants   = [ "nginx.service" ];
        after   = ["systemd-tmpfiles-setup.service"  "nginx.service" ];
        bindsTo = [ "nginx.service" ];
      };
    };
    tmpfiles.rules = [
      "d  /persist/var/lib/postgresql 0755 josh wheel - -"

      "d  /persist/var/lib/bitwarden_rs 0755 vaultwarden vaultwarden - -"
      "L+ /var/lib/bitwarden_rs         - - - - /persist/var/lib/bitwarden_rs"

      "d  /persist/var/lib/acme 0755 acme acme - -"
      "L+ /var/lib/acme         - - - - /persist/var/lib/acme"
    ];
  };
  fileSystems."/var/lib/postgresql" = { device = "/persist/var/lib/postgresql"; options = [ "bind" ]; };
}
