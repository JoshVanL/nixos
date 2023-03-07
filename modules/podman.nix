{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.services.josh.podman;
in {
  options.services.josh.podman = {
    enable = mkEnableOption "podman";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      podman-dompose
      dive
      paranoia
    ];

    virtualisation = {
      podman = {
        enable = true;

        # Create a `docker` alias for podman, to use it as a drop-in
        # replacement.
        dockerCompat = true;

        extraPackages = [ pkgs.zfs ];
      };
    };
  };
}
