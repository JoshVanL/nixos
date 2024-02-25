{ lib, pkgs, config, ... }:
with lib;

let
  cfg = config.me.roles;

in {
  config = mkIf (elem "cacheserver" cfg.assume) {
    me.data.cache = {
      nix = {
        enable = true;
        domain = "nixcache.joshvanl.dev";
        cacheDir = "/keep/run/nginx/cache/nix";
        maxCacheSize = "300G";
        maxCacheAge = "180d";
      };
      machine = {
        enable = false;
        domain = "machinecache.joshvanl.dev";
        secretKeyFile = "/persist/etc/joshvanl/machinecache/cache-priv-key.pem";
        machineRepo = "https://github.com/joshvanl/nixos";
        timerOnCalendar = "*-*-* 4:00:00";
      };
      go = {
        enable = false;
        domain = "gocache.joshvanl.dev";
      };
      container = {
        enable = true;
        domain = "containercache.joshvanl.dev";
        registries = [
          {name = "docker.io"; upstream = "registry-1.docker.io";}
          "ghcr.io"
          "quay.io"
          "registry.k8s.io"
          "mcr.microsoft.com"
        ];
      };
    };
  };
}
