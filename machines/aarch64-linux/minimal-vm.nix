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
    initrd = {
      availableKernelModules = [ "xhci_pci" "usbhid" "sr_mod" ];
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
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    step-cli
  ];

  networking = {
    hostName = "minimal-vm";
    hostId = "deadbeef";
    interfaces.enp0s5.useDHCP = true;

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

  hardware.parallels.enable = true;

  nixpkgs.config = {
    allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "prl-tools" ];
    allowUnsupportedSystem = true;
  };

  users.users.josh.openssh.authorizedKeys.keys = authorizedKeys;

  services = {
    josh = {
      tailscale.enable = true;
    };
    openssh = {
      enable = true;
      passwordAuthentication = true;
      kbdInteractiveAuthentication = true;
    };
  };
}
