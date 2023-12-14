{ lib, pkgs, config, ... }:
with lib;

let
  cfg = config.me.roles;

in {
  config = mkIf (elem "mediaserver" cfg.assume) {
    me.data.media = {
      radarr = {
        enable = false;
        domain = "dish.joshvanl.dev";
      };
      sonarr = {
        enable = false;
        domain = "sat.joshvanl.dev";
      };
      jackett = {
        enable = false;
        domain = "hoodie.joshvanl.dev";
      };
      plex = {
        enable = true;
        domain = "plex.joshvanl.dev";
      };
    };
  };
}
