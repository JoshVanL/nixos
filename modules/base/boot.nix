{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.base.boot;

in {
  options.me.base.boot = {
    kernelPackages = mkOption {
      default = null;
    };

    kernelParams = mkOption {
      default = [ ];
      type = types.listOf types.str;
    };

    loader = mkOption {
      default = "systemd-boot";
      type = types.enum [ "systemd-boot" "raspberrypi" ];
    };

    initrd = {
      availableKernelModules = mkOption {
        default = [ ];
        type = types.listOf types.str;
      };

      ssh = {
        enable = mkOption {
          default = false;
          type = types.bool;
        };

        authorizedKeys = mkOption {
          default = [ ];
          type = types.listOf types.str;
        };
      };
    };
  };

  config = {
    boot = {
      # Clense with fire.
      initrd = {
        availableKernelModules = cfg.initrd.availableKernelModules;
        postDeviceCommands = lib.mkAfter ''
          zfs rollback -r rpool/local/root@blank
        '';

        network = mkIf cfg.initrd.ssh.enable {
          enable = true;
          ssh = {
            enable = true;
            port = 22;
            ignoreEmptyHostKeys = true;
            authorizedKeys = cfg.initrd.ssh.authorizedKeys;
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

      zfs = {
        requestEncryptionCredentials = true;
        devNodes = "/dev/disk/by-label/rpool";
      };

      kernelPackages = mkIf (cfg.kernelPackages != null) cfg.kernelPackages;
      kernelParams = cfg.kernelParams;
      kernelModules = [ ];
      extraModulePackages = [ ];
      supportedFilesystems = [ "vfat" "zfs" ];

      loader = {
        efi.canTouchEfiVariables = true;
        grub.enable = false;

        systemd-boot.enable = cfg.loader == "systemd-boot";
        raspberryPi = mkIf (cfg.loader == "raspberrypi") {
          enable = true;
          version = 4;
        };
      };
    };
  };
}