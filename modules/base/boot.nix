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
    emulatedSystems = mkOption {
      default = [ ];
      type = types.listOf types.str;
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

    systemd.services.zfs-rollback-shutdown = {
      description = "Rollback ZFS on shutdown";
      wantedBy = [ "shutdown.target" "reboot.target" ];
      before = [ "shutdown.target" "reboot.target" ];
      after = [ "zfs-mount.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = false;
        ExecStart = "${pkgs.zfs}/bin/zfs rollback -r rpool/local/root@blank";
      };
    };

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
            mkdir -p /boot/ssh /etc/ssh
            if [[ ! -f /boot/ssh/ssh_host_ed25519_key ]]; then
              ${pkgs.step-cli}/bin/step crypto keypair -f --kty=OKP --crv=Ed25519 --no-password --insecure /boot/ssh/pub /boot/ssh/priv
              ${pkgs.step-cli}/bin/step crypto key format -f --no-password --insecure --ssh --out /boot/ssh/ssh_host_ed25519_key /boot/ssh/priv
              ${pkgs.step-cli}/bin/step crypto key format -f --no-password --insecure --ssh --out /boot/ssh/ssh_host_ed25519_key.pub /boot/ssh/pub
            fi
            cp /boot/ssh/ssh_host_ed25519_key /etc/ssh/ssh_host_ed25519_key
            cp /boot/ssh/ssh_host_ed25519_key.pub /etc/ssh/ssh_host_ed25519_key.pub
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
      binfmt.emulatedSystems = cfg.emulatedSystems;

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
