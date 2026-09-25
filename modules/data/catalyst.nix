{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.data.catalyst;

  jobsFile = pkgs.writeText "catalyst-cron.json" (builtins.toJSON (mapAttrsToList (name: job: {
    inherit name;
    inherit (job) cron unit;
  } // optionalAttrs (job.user != null) { inherit (job) user; }) cfg.jobs));

in {
  options.me.data.catalyst = {
    enable = mkEnableOption "schedule jobs with Dapr workflows on Diagrid Catalyst, in place of systemd timers";

    envFile = mkOption {
      type = types.str;
      default = "/persist/etc/catalyst/${config.me.machineName}.env";
      description = ''
        EnvironmentFile holding DAPR_GRPC_ENDPOINT, DAPR_HTTP_ENDPOINT and
        DAPR_API_TOKEN of this machine's Catalyst App ID.
      '';
    };

    jobs = mkOption {
      default = {};
      description = "systemd units to start on a cron schedule.";
      type = types.attrsOf (types.submodule {
        options = {
          cron = mkOption {
            type = types.str;
            description = ''
              Standard 5 field cron spec, in this machine's time zone.
              Prefix with `CRON_TZ=<zone>` to use another zone.
            '';
          };
          unit = mkOption {
            type = types.str;
          };
          user = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Start `unit` as a user unit of this user.";
          };
        };
      });
    };
  };

  config = mkIf cfg.enable {
    systemd.services.catalyst-cron = {
      description = "Catalyst workflow scheduler";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ config.systemd.package ];
      # Skip cleanly until the Catalyst App ID has been set up.
      unitConfig.ConditionPathExists = cfg.envFile;
      serviceConfig = {
        ExecStart = "${pkgs.catalyst-cron}/bin/catalyst-cron --config ${jobsFile}";
        EnvironmentFile = cfg.envFile;
        Restart = "always";
        RestartSec = "10s";
      };
    };
  };
}
