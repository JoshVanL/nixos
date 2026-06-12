{ lib, config, ... }:
with lib;
let
  cfg = config.me.dev.diagrid;

in {
  options.me.dev.diagrid = {
    enable = mkEnableOption "dev.diagrid";
  };

  config = mkIf cfg.enable {
    # onebox drives kind, which needs a rootful container engine: rootless
    # podman cannot remount /lib/modules inside the user namespace (locked
    # nosuid,nodev mount flags) and cannot bind ports 80/443.
    virtualisation.docker = {
      enable = true;
      # Keep image and cluster state off the ephemeral root, otherwise the
      # zfs storage driver leaks layer datasets under the rolled-back root.
      daemon.settings.data-root = "/keep/var/lib/docker";
    };

    # The podman module enables dockerCompat, which conflicts with the real
    # docker socket and CLI.
    virtualisation.podman.dockerCompat = mkForce false;

    users.users.${config.me.username}.extraGroups = [ "docker" ];

    networking.hosts."127.0.0.1" = [
      "localhost.local.diagrid.io"
      "admin.local.diagrid.io"
      "api.local.diagrid.io"
      "tunnels.api.local.diagrid.io"
      "admingrid.local.diagrid.io"
      "cloudgrid.local.diagrid.io"
      "cra.local.diagrid.io"
      "trust.local.diagrid.io"
      "metrics.local.diagrid.io"
      "cra-metrics.local.diagrid.io"
      "logs.local.diagrid.io"
      "cra-logs.local.diagrid.io"
      "mgmt-onebox-agent-onebox.api.local.diagrid.io"
      "http-prj4.api.local.diagrid.io"
      "grpc-prj4.api.local.diagrid.io"
      "conductor.local.diagrid.io"
      "catalyst-cloud.local.diagrid.io"
      "catalyst-logs.local.diagrid.io"
      "catalyst-metrics.local.diagrid.io"
      "catalyst.local.diagrid.io"
      "sentry.local.diagrid.io"
      "oidc.local.diagrid.io"
      "tunnel-proxy.local.diagrid.io"
      "tunnel-upstream.local.diagrid.io"
    ];
  };
}
