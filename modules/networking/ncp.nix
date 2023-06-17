{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.networking.ncp;

in {
  options.me.networking.ncp = { };

  config = {
    services.timesyncd.enable = mkForce true;
    systemd.additionalUpstreamSystemUnits = [ "systemd-time-wait-sync.service" ];
    systemd.services.systemd-time-wait-sync.wantedBy = [ "default.target" ];
  };
}
