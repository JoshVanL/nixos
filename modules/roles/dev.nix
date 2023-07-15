{ lib, pkgs, config, ... }:
with lib;

let
  cfg = config.me.roles;

in {
  config = mkIf (elem "dev" cfg.assume) {
    me = {
      dev = {
        git = {
          enable = true;
          username = "joshvanl";
          email = "me@joshvanl.dev";
        };
        build.enable = true;
        c.enable = true;
        cloud.enable = true;
        crypto.enable = true;
        go = {
          enable = true;
          extraProxies = ["http://gocache.joshvanl.dev"];
        };
        grpc.enable = true;
        kube.enable = true;
        data.enable = true;
        image.enable = true;
        python.enable = true;
        rust.enable = true;
      };

      networking.podman = {
        enable = true;
        mirrorDomain = "containercache.joshvanl.dev";
        mirrors = [
          "docker.io"
          "ghcr.io"
          "quay.io"
          "registry.k8s.io"
          "mcr.microsoft.com"
        ];
      };
    };
  };
}
