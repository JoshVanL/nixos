{ lib, pkgs, config, ... }:

with lib;
{
  options.me.security.joshvanl = {
    sshPublicKeys = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of joshvanl's SSH public keys";
    };

    yubikeyIDs = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of joshvanl's Yubikey client IDs";
    };

    nixPublicKeys = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of public keys for NixOS binary cache substituters";
    };

    wireguard = mkOption {
      type = types.attrs;
      default = {};
      description = "Wireguard configuration";
    };
  };

  config = {
    me.security.joshvanl = {
      sshPublicKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8f6d0e0AsHrOvImhh1HsFczFRX5grwrFN1b4Bq0ZCq0kn/e/mBJD66BwXLQa5/emeP66YXP975+pquIJ463rGfoZuNR9ocD6V+uQkuqr8axm8bBiSqwqIVrzoPAl6Uk5QrNtGztTdv/iULq45qrgSF4EIa+ZvvoggwmPhzI6XFboheUuGTW9ktS3/Fa6Jmlz7pYvK4RNRhxpNMpCkjG2jYpVzLsiZhqiLK6Wk+cyGZ3FZx5lNQgBDUoR1Nzfmb21NC8MYapmTl0eCSH9asOMuGBGlgSFNhLsZhvMYCXB6GZ/lDn70J37XTtRcirHoXEDfePcE/pYLP3/rNjv1UA39"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCaBFpBKuTdsanEImU0BhICRbw9U6V3zCtgksyEhZv65iYEoTrxtRH6BIcMB7onSLjgNj+do+vaQH+yXGrmZc1zfWIynso4vzaZpqNgthIbXaXR3iwRh6FyE9PQx4iOgNVv3DznKZMdVhrlW9NliWHxFv27saUOqLefm9qdIhWWfgrl8y4JxRCTPKIFonIqU2dg4EZXXqJJlEQNU9lkOybncQSfH4zykrJYRIJ/XHMUxQEXO02tqdSqSuhVhv1fxAfF33o+HBhASN50uWB2qh3gHb95pqWm3nQa9OLk66YffviWkURxhXhiCdv5A9aOsCvUTEg/PQrVeJFAu4VMNtJR"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDeppp8Ozc2Fzbe9SwWu6lcC7y4Fh0bRBIO9sMqXRWuOToV/IDLq9gcF9Qx/X48sQOETMJHpYK8aQgAoDuJPGutmWpJf8OyfkGtnc1pwpaAtwwfXzc91uUwRP7MevseRiu3tOVZdXS39xNUbEqJgXLhZVb+Ai+CBDQ7t1vyZ3KwtxGIXTc+BCPuQZ/GKdzxFzdVgaDKLChEJaecYNkzqSZ2ZnF9qwG/4RowEwyKDFDvRqXUEGEZAcYlJ2KDQQvk94MsNhFWRHFNGKYpTcbL69WxSXZQariiASjU1oWzCwQYPtd05TX0F7IkFk80jyp8HM9cM6J3iDF6xrOycLS7m4RgojKTpBTBDCpyaUrWN7PfSVIMQE/KGKIlnr4RT2ewubmPSWqS4ohWF7pZx6MrpQIRynMl8GxXTUy1nnlAPFrqnre0Qahg+5E3Id36f+5yi+kM0C4N7KIzR5cXT+gGCMcmXqtjTowOLDRpwZ9UuiEN4wjey+7OfGUdLW2AU/wsZo5kQ0IrvjQnZVAQVVHViDxTv8FlIdII2wVc/AgOdnTbgS4t5pxf+/XD6flVRpAdRb5pttC0iYnXfh2gueUG546qgsXoHAxo7ymT/zbLe8lmN2zwiZlkwVQ47RWYPtgWvuP2/4ebQ584nGq1hPzx1RKrOdSNZODd/wRjPytD6k5J/w=="
        # navy
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAINJi8FX/b+2qsAeEN8KfTe7rP1+bCXvmZ/oxyhcAcvTVAAAABHNzaDo="
        # gold-fido
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIFOiIRyDiW99jt4klbFBwWYaUDbt9x33vab+lummvaA2AAAABHNzaDo="
      ];

      yubikeyIDs = [
        "cccccbegbgvj"
        "cccccclbfjcf"
      ];

      nixPublicKeys = [
        "machinecache.joshvanl.dev:Xc64ijCADm4FAsbQJI+J1ku8JKXPqrZHckKAf1jhrWA="
      ];

      wireguard = {
        uk = {
          enable = true;
          privateKeyFile = "/persist/etc/wireguard/private_key_uk";
          addresses = [ "10.2.0.2/32" ];
          dns = [ "10.2.0.1" ];
          peer = {
            endpoint = "146.70.83.66:51820";
            publicKey = "lnSLhBJ3zosn36teAK1JJjn7ALiaPLq5k6YO07GnQi4=";
          };
        };
        costa = {
          enable = true;
          privateKeyFile = "/persist/etc/wireguard/private_key_costa";
          addresses = [ "10.2.0.2/32" ];
          dns = [ "10.2.0.1" ];
          peer = {
            endpoint = "138.199.50.104:51820";
            publicKey = "kqT/fYDDcxeDHNn1sZQA8XVXZI98+9IjeDQ5gEPtMyg=";
          };
        };
        italy = {
          enable = true;
          privateKeyFile = "/persist/etc/wireguard/private_key_italy";
          addresses = [ "10.2.0.2/32" ];
          dns = [ "10.2.0.1" ];
          peer = {
            endpoint = "146.70.182.34:51820";
            publicKey = "QAx4kzh5ejS9RksrRPqv8u/d0eY3WMrMyvykPJZTN3M=";
          };
        };
      };
    };
  };
}
