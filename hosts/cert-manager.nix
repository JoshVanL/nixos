{ lib, pkgs, config, ... }:

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
  joshvanlPath = "/persist/etc/joshvanl";
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
          authorizedKeys = authorizedKeys;
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
    hostName = "cert-manager";
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

  users.users.josh.openssh.authorizedKeys.keys = authorizedKeys;
  home-manager.users.josh = { pkgs, ... }: {
    pam.yubico.authorizedYubiKeys.ids = [ ]
    ++ lib.optional (builtins.pathExists "${joshvanlPath}/yubikey/otp-client-id-1") (builtins.readFile "${joshvanlPath}/yubikey/otp-client-id-1")
    ++ lib.optional (builtins.pathExists "${joshvanlPath}/yubikey/otp-client-id-2") (builtins.readFile "${joshvanlPath}/yubikey/otp-client-id-2")
    ;
  };

  environment.systemPackages = with pkgs; [
    kubectl
    kind
    cmctl
  ];

  services = {
    openssh = {
      enable = true;
      passwordAuthentication = false;
      kbdInteractiveAuthentication = true;
    };
  };

  security = {
    pam.yubico = { enable = true; id = "16"; };
  };
}
