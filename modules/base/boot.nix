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
    raspPi4Firmware = mkOption {
      type = types.bool;
      default = false;
    };

    initrd = {
      availableKernelModules = mkOption {
        default = [ ];
        type = types.listOf types.str;
      };
      supportedFilesystems = [ "zfs" ];

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
        # systemd stage 1, except where initrd SSH is used: its key generation
        # and unlock flow below are scripted-only and are ported separately,
        # with a console at hand.
        systemd = {
          enable = !cfg.initrd.ssh.enable;
          # Roll the root dataset back to blank before it is mounted.
          services.rollback = mkIf (!cfg.initrd.ssh.enable) {
            description = "Roll back rpool/local/root to the blank snapshot";
            wantedBy = [ "initrd.target" ];
            after = [ "zfs-import-rpool.service" ];
            before = [ "sysroot.mount" ];
            unitConfig.DefaultDependencies = "no";
            serviceConfig.Type = "oneshot";
            script = "zfs rollback -r rpool/local/root@blank";
          };
        };

        availableKernelModules = cfg.initrd.availableKernelModules;
        postResumeCommands = mkIf cfg.initrd.ssh.enable (lib.mkAfter ''
          zfs rollback -r rpool/local/root@blank
        '');

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
            find /dev/disk | ${pkgs.findutils}/bin/xargs ls -l -
            if [[ ! -f /boot/ssh/ssh_host_ed25519_key ]]; then
              ${pkgs.step-cli}/bin/step crypto keypair -f --kty=OKP --crv=Ed25519 --no-password --insecure /boot/ssh/pub /boot/ssh/priv
              ${pkgs.step-cli}/bin/step crypto key format -f --no-password --insecure --ssh --out /boot/ssh/ssh_host_ed25519_key /boot/ssh/priv
              ${pkgs.step-cli}/bin/step crypto key format -f --no-password --insecure --ssh --out /boot/ssh/ssh_host_ed25519_key.pub /boot/ssh/pub
            fi
            cp /boot/ssh/ssh_host_ed25519_key /etc/ssh/ssh_host_ed25519_key
            cp /boot/ssh/ssh_host_ed25519_key.pub /etc/ssh/ssh_host_ed25519_key.pub
            zpool import -a
            echo "zfs load-key -a; killall zfs" >> /root/.profile
          '';
        };
      };

      zfs = {
        requestEncryptionCredentials = true;
        # zpool import -f for the root pool. Revisit with the initrd SSH port.
        forceImportRoot = true;
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
