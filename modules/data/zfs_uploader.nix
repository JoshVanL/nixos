{ lib, pkgs, config, nixosConfig, ... }:

with lib;
let
  cfg = config.me.data.zfs_uploader;

  backupSH = pkgs.writeShellApplication {
    name = "backup.sh";
    runtimeInputs = with pkgs; [ zfs zfs_uploader ];
    text = ''
      PYTHONUNBUFFERED=1 zfsup --config-path ${cfg.configPath} --log-path "${cfg.logPath}" backup
    '';
  };

in {
  options.me.data.zfs_uploader = {
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
    home-manager.users.${config.me.base.username}.home.packages = with pkgs; [
      zfs_uploader
      backblaze-b2
    ];

    systemd = {
      tmpfiles.rules = [
        "d ${dirOf cfg.configPath} 0755 ${config.me.base.username} wheel - -"
        "d ${dirOf cfg.logPath} 0755 ${config.me.base.username} wheel - -"
      ];

      services.zfs_uploader = {
        enable = true;
        description = "ZFS snapshot to S3 uploader";
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "simple";
          User = "root";
          Group = "root";
          WorkingDirectory = "/tmp";
          ExecStart = "${backupSH}/bin/backup.sh";
          Restart = "on-failure";
        };
        wantedBy = [ "default.target" ];
      };
    };

    # Helper functions:
    # export PATH=$PATH:${pkgs.zfs}/bin
    # $ zfs list -t snapshot
    # $ B2_APPLICATION_KEY_ID=xxx B2_APPLICATION_KEY=xxx backblaze-b2  download-file-by-name xxx rpool/safe/persist/xxxx.full persist.full
    # $ sudo zfs receive -F -v rpool/safe/restore < persist.full
    # $ sudo zfs receive -F -v rpool/safe/restore < persist.inc
    # $ sudo zfs load-key -r rpool/safe/restore
    # $ sudo zfs set mountpoint=legacy rpool/safe/restore
    # $ sudo mount -t zfs rpool/safe/restore foo
  };
}
