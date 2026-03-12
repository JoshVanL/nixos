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
          #extraProxies = ["http://gocache.joshvanl.dev"];
        };
        grpc.enable = true;
        kube.enable = true;
        data.enable = true;
        image.enable = true;
        python.enable = true;
        rust.enable = true;
        dotnet.enable = true;
        node.enable = true;
        ai.enable = true;
      };

      shell.cdgo = {
        enable = true;
        groups = {
          daprgo = [
            "dapr/dapr"
            "dapr/durabletask-protobuf"
            "dapr/proposals"
            "dapr/durabletask-go"
            "dapr/kit"
            "dapr/components-contrib"
            "dapr/go-sdk"
            "dapr/cli"
          ];
        };
      };

      networking.podman = {
        enable = true;
        #mirrorDomain = "containercache.joshvanl.dev";
        #mirrors = [
        #  "docker.io"
        #  "ghcr.io"
        #  "quay.io"
        #  "registry.k8s.io"
        #  "mcr.microsoft.com"
        #];
      };
    };
  };
}
