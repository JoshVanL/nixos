{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.programs.podman;

  docker-compose-alias = pkgs.stdenv.mkDerivation {
    name = "docker-compose";
    src = pkgs.podman-compose;
    installPhase = ''
      mkdir -p $out/bin
      ln -s $src/bin/podman-compose $out/bin/docker-compose
    '';
  };

in {
  options.me.programs.podman = {
    enable = mkEnableOption "podman";
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.me.base.username}.home.packages = with pkgs; [
      podman-compose
      docker-compose-alias
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
