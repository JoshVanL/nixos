{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.services.josh.zfs_uploader;
in {
  options.services.josh.zfs_uploader = {
    enable = mkEnableOption "zfs_uploader";

    configPath = mkOption {
      type = types.str;
      default = "";
    };

    logPath = mkOption {
      type = types.str;
      default = "";
    };
  };

  config = mkIf cfg.enable {
    nixpkgs.config.packageOverrides = super: {
      zfs_uploader = pkgs.callPackage /keep/etc/nixos/pkgs/zfs_uploader {
        python3 = pkgs.python3;
        python3Packages = pkgs.python3Packages;
      };
    };

    environment.systemPackages = with pkgs; [
      zfs_uploader
    ];

    systemd.tmpfiles.rules = [
      "d ${dirOf cfg.configPath} 0755 josh wheel - -"
      "d ${dirOf cfg.logPath} 0755 josh wheel - -"
    ];

    environment.etc = {
      "joshvanl/backup/run.sh" = {
        text = ''
          #!/bin/usr/env bash

          export PYTHONUNBUFFERED=1
          export PATH=$PATH:${pkgs.zfs}/bin
          ${pkgs.zfs_uploader}/bin/zfsup --config-path ${cfg.configPath} --log-path ${cfg.logPath} backup
        '';

        mode = "755";
      };
    };


    systemd.services.zfs_uploader = {
      enable = true;
      description = "ZFS snapshot to S3 uploader";
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type             = "simple";
        User             = "root";
        Group            = "root";
        WorkingDirectory = "/tmp";
        ExecStart        = "${pkgs.bash}/bin/bash /etc/joshvanl/backup/run.sh";
        Restart          = "on-failure";
      };
      wantedBy = [ "default.target" ];
    };

    # Helper functions:
    # $ zfs list -t snapshot
    # $ B2_APPLICATION_KEY_ID=xxx B2_APPLICATION_KEY=xxx backblaze-b2  download-file-by-name xxx rpool/safe/persist/xxxx.full persist.full
    # $ sudo zfs receive -F -v rpool/safe/restore < persist.full
    # $ sudo zfs receive -F -v rpool/safe/restore < persist.inc
    # $ sudo zfs load-key -r rpool/safe/restore
    # $ sudo zfs set mountpoint=legacy rpool/safe/restore
    # $ sudo mount -t zfs rpool/safe/restore foo
  };
}
