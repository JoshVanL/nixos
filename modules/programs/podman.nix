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
    mirrorDomain = mkOption {
      type = types.str;
      description = ''
        The domain to use for the mirror.
      '';
      default = "";
    };
    mirrors = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        A list of registries which are mirrored on the mirror doamin.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = (length cfg.mirrors > 0) == ((stringLength cfg.mirrorDomain) > 0);
        message = "If you set a mirror domain, you must also set at least one mirror.";
      }
    ];

    home-manager.users.${config.me.base.username} = {
      home.packages = with pkgs; [
        podman-compose
        docker-compose-alias
        dive
        paranoia
      ];
      xdg.configFile."containers/registries.conf".text = ''
        unqualified-search-registries = ["docker.io", "quay.io"]
      '' + strings.concatStrings(forEach cfg.mirrors (mirror: ''

        [[registry]]
        prefix = "${mirror}"
        insecure = true
        location = "${cfg.mirrorDomain}/${mirror}"
      ''));
    };

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
