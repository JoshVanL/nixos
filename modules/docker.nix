{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.services.josh.docker;
in {
  options.services.josh.docker = {
    enable = mkEnableOption "docker";
  };

  config = mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      storageDriver = "zfs";
    };
    systemd.services.docker.wantedBy = lib.mkForce [];

    environment.systemPackages = with pkgs; [
      docker-compose
    ];
  };
}
