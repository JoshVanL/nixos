{ lib, pkgs, config, nixosConfig, ... }:

with lib;
let
  cfg = config.me.data.zfs_uploader;
  catalyst = config.me.data.catalyst.enable;

  backupSH = pkgs.writeShellApplication {
    name = "backup.sh";
    runtimeInputs = with pkgs; [ zfs zfs_uploader gnused coreutils ];
    text = if catalyst then ''
      # Without cron in the config, zfsup runs each job once and exits,
      # leaving the scheduling to Catalyst.
      CONFIG=$(mktemp)
      trap 'rm -f -- "$CONFIG"' EXIT
      sed '/^cron *=/d' ${cfg.configPath} > "$CONFIG"
      PYTHONUNBUFFERED=1 zfsup --config-path "$CONFIG" --log-path "${cfg.logPath}" backup
    '' else ''
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

    cron = mkOption {
      type = types.str;
      default = "0 13 * * *";
      description = "Backup schedule when me.data.catalyst is enabled. Otherwise the cron in configPath is used.";
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.me.username}.home.packages = with pkgs; [
      zfs_uploader
      backblaze-b2
    ];

    systemd = {
      tmpfiles.rules = [
        "d ${dirOf cfg.configPath} 0755 ${config.me.username} wheel - -"
        "d ${dirOf cfg.logPath} 0755 ${config.me.username} wheel - -"
      ];

      services.zfs_uploader = {
        enable = true;
        description = "ZFS snapshot to S3 uploader";
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = if catalyst then "oneshot" else "simple";
          User = "root";
          Group = "root";
          WorkingDirectory = "/tmp";
          ExecStart = "${backupSH}/bin/backup.sh";
          Restart = mkIf (!catalyst) "on-failure";
        };
        wantedBy = mkIf (!catalyst) [ "default.target" ];
      };
    };

    me.data.catalyst.jobs.zfs-backup = mkIf catalyst {
      cron = cfg.cron;
      unit = "zfs_uploader.service";
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
