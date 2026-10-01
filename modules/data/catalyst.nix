{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.data.catalyst;
  agents = cfg.agents;

  jobsFile = pkgs.writeText "catalyst-cron.json" (builtins.toJSON (mapAttrsToList (name: job: {
    inherit name;
    inherit (job) cron;
  } // filterAttrs (_: v: v != null) {
    inherit (job) unit user workflow appId input;
  } // optionalAttrs (agents.enable && job.unit != null) {
    doctor = agents.appId;
  }) cfg.jobs));

  agentsConfig = pkgs.writeText "catalyst-agents.json" (builtins.toJSON {
    inherit (agents) llmComponent;
    repo = "/keep/etc/nixos";
    machine = config.me.machineName;
    bump = mapAttrs (_: t: t.instructions) agents.bump;
  });

in {
  options.me.data.catalyst = {
    enable = mkEnableOption "schedule jobs with Dapr workflows on Diagrid Catalyst, in place of systemd timers";

    appId = mkOption {
      type = types.str;
      default = "${config.me.machineName}-systemd-timers";
      description = "Catalyst App ID of catalyst-cron, whose credentials `envFile` holds.";
    };

    envFile = mkOption {
      type = types.str;
      default = "/persist/etc/catalyst/${cfg.appId}.env";
      description = ''
        EnvironmentFile holding DAPR_GRPC_ENDPOINT, DAPR_HTTP_ENDPOINT and
        DAPR_API_TOKEN of `appId`.
      '';
    };

    notifyUser = mkOption {
      type = types.nullOr types.str;
      default = config.me.username;
      description = "User shown job failures, and results that ask for it, as desktop notifications.";
    };

    jobs = mkOption {
      default = {};
      description = "systemd units, or workflows of other Catalyst App IDs, to run on a cron schedule.";
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
            type = types.nullOr types.str;
            default = null;
          };
          user = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Start `unit` as a user unit of this user.";
          };
          workflow = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              In place of `unit`, a workflow of App ID `appId` to run with
              `input`. It returns `{ summary, notify }`.
            '';
          };
          appId = mkOption {
            type = types.nullOr types.str;
            default = null;
          };
          input = mkOption {
            type = types.nullOr types.str;
            default = null;
          };
        };
      });
    };

    agents = {
      enable = mkEnableOption ''
        Dapr Agents on Catalyst: job-doctor explains why a job's unit
        failed, and bump keeps pinned packages up to date on branches
      '';

      appId = mkOption {
        type = types.str;
        default = "${config.me.machineName}-agents";
        description = "Catalyst App ID of the agents, whose credentials `envFile` holds.";
      };

      envFile = mkOption {
        type = types.str;
        default = "/persist/etc/catalyst/${agents.appId}.env";
        description = ''
          EnvironmentFile holding DAPR_GRPC_ENDPOINT, DAPR_HTTP_ENDPOINT and
          DAPR_API_TOKEN of `appId`.
        '';
      };

      llmComponent = mkOption {
        type = types.str;
        default = "llm";
        description = "Catalyst conversation component the agents use as their LLM.";
      };

      bump = mkOption {
        default = {};
        description = ''
          Pins in this repo to bump, each by an agent that commits to branch
          bump/<name> of /keep/etc/nixos. Merging is left to you.
        '';
        type = types.attrsOf (types.submodule {
          options = {
            cron = mkOption {
              type = types.str;
              description = "When to check for a new release, as in `jobs`.";
            };
            instructions = mkOption {
              type = types.lines;
              description = "Where the pin is, and where its releases, sources and notes are.";
            };
          };
        });
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # For `catalyst-cron run`, and its completion of job names.
      environment.systemPackages = [ pkgs.catalyst-cron ];
      environment.etc = {
        "catalyst-cron/jobs.json".source = jobsFile;
        "catalyst-cron/env".source = cfg.envFile;
      };

      systemd.services.catalyst-cron = {
        description = "Catalyst workflow scheduler";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        path = [ config.systemd.package pkgs.libnotify ];
        # Skip cleanly until the Catalyst App ID has been set up.
        unitConfig.ConditionPathExists = cfg.envFile;
        serviceConfig = {
          ExecStart = "${pkgs.catalyst-cron}/bin/catalyst-cron serve --config ${jobsFile}"
            + optionalString (cfg.notifyUser != null) " --notify-user ${cfg.notifyUser}";
          EnvironmentFile = cfg.envFile;
          Restart = "always";
          RestartSec = "10s";
        };
      };
    }

    (mkIf agents.enable {
      me.data.catalyst.jobs = mapAttrs' (name: t: nameValuePair "bump-${name}" {
        inherit (t) cron;
        workflow = "bump";
        appId = agents.appId;
        input = name;
      }) agents.bump;

      me.data.catalyst.agents.bump = {
        claude-code = {
          cron = mkDefault "0 9 * * 1";
          instructions = ''
            Pin: overlays/claude-code.nix, a version and a hash per system.
            Latest version: the "version" field of https://registry.npmjs.org/@anthropic-ai/claude-code/latest
            Sources: https://registry.npmjs.org/@anthropic-ai/claude-code-SUFFIX/-/claude-code-SUFFIX-VERSION.tgz with SUFFIX linux-x64 for x86_64-linux and linux-arm64 for aarch64-linux. They use fetchzip, so prefetch each with unpack.
            Build attribute: pkgs.claude-code
            Release notes: https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md
          '';
        };
        diagrid-cli = {
          cron = mkDefault "15 9 * * 1";
          instructions = ''
            Pin: pkgs/diagrid-cli/default.nix, a version and a hash per system.
            Latest version: the RELEASE_VERSION default in https://downloads.diagrid.io/cli/install.sh
            Sources: https://storage.googleapis.com/bkt-p-cli-common-us-central1-95640/vVERSION/diagrid/diagrid_linux_ARCH/diagrid_linux_ARCH.tar.gz with ARCH amd64 for x86_64-linux and arm64 for aarch64-linux. They use fetchurl, so prefetch each without unpack.
            Build attribute: pkgs.diagrid-cli
            Release notes: none are published, so leave the commit body empty.
          '';
        };
        dapr-cli = {
          cron = mkDefault "30 9 * * 1";
          instructions = ''
            Pin: dapr-cli in overlays/dapr.nix: version, the fetchFromGitHub sha256, and vendorHash.
            Latest version: tag_name of https://api.github.com/repos/dapr/cli/releases/latest
            Source hash: prefetch https://github.com/dapr/cli/archive/refs/tags/vVERSION.tar.gz with unpack.
            Build attribute: pkgs.dapr-cli
            Release notes: the body of that GitHub release.
            The overlay builds with go_1_26_4. If the go directive in https://raw.githubusercontent.com/dapr/cli/vVERSION/go.mod needs a newer Go, reply with the Go version needed and do not commit.
          '';
        };
        flake-lock = {
          cron = mkDefault "0 10 * * 1";
          instructions = ''
            Pin: flake.lock. This target replaces steps 1 to 5:
            Run flake_update with no inputs. If nothing changed, reply 'flake.lock up to date' and stop.
            Build the whole system (empty build attribute). Fix small breakages in the repo's modules, such as a renamed or removed nixpkgs package or option. For anything bigger, reply with the failing derivation and its error, and do not commit.
            Commit with the first line 'flake.lock: update', and a body listing each input that moved with its old and new revision date.
          '';
        };
      };

      systemd.services.catalyst-agents = {
        description = "Dapr Agents on Catalyst: job-doctor and bump";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        path = [ config.nix.package config.systemd.package pkgs.git ];
        environment = {
          CATALYST_AGENTS_CONFIG = agentsConfig;
          # The real home is hidden, so nix and git keep their caches here.
          HOME = "/var/lib/catalyst-agents";
          GIT_AUTHOR_NAME = "catalyst-agents";
          GIT_AUTHOR_EMAIL = "catalyst-agents@${config.me.machineName}";
          GIT_COMMITTER_NAME = "catalyst-agents";
          GIT_COMMITTER_EMAIL = "catalyst-agents@${config.me.machineName}";
        };
        # Skip cleanly until the agents' App ID has been set up.
        unitConfig.ConditionPathExists = agents.envFile;
        serviceConfig = {
          ExecStart = getExe pkgs.catalyst-agents;
          # Bump commits to the user's repo, and job-doctor reads the user's
          # journal and unit files.
          User = config.me.username;
          EnvironmentFile = agents.envFile;
          # Holds the bump worktrees.
          StateDirectory = "catalyst-agents";
          Restart = "always";
          RestartSec = "10s";

          # Sandbox. The filesystem is read-only, with home, /keep and
          # /persist hidden, apart from: the repo (read-only, with .git
          # writable for the bump branches), the user's unit files, and the
          # state directory. No devices, capabilities, or new privileges.
          ProtectSystem = "strict";
          ProtectHome = "tmpfs";
          TemporaryFileSystem = [ "/keep:ro" "/persist:ro" ];
          BindReadOnlyPaths = [
            "/keep/etc/nixos"
            "-/home/${config.me.username}/.config/systemd/user"
          ];
          BindPaths = [ "/keep/etc/nixos/.git" ];
          PrivateTmp = true;
          PrivateDevices = true;
          PrivateIPC = true;
          ProtectProc = "invisible";
          ProtectHostname = true;
          ProtectClock = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectKernelLogs = true;
          ProtectControlGroups = true;
          NoNewPrivileges = true;
          CapabilityBoundingSet = "";
          RestrictSUIDSGID = true;
          RestrictNamespaces = true;
          RestrictRealtime = true;
          LockPersonality = true;
          RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
          SystemCallArchitectures = "native";
          SystemCallFilter = [ "@system-service" ];
        };
      };
    })
  ]);
}
