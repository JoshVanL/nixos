{ lib, pkgs, config, ... }:
with lib;

let
  cfg = config.me.roles;

in {
  config = mkIf (elem "mediaserver" cfg.assume) {
    me.data.media = {
      radarr = {
        enable = true;
        domain = "dish.joshvanl.dev";
      };
      jackett = {
        enable = true;
        domain = "hoodie.joshvanl.dev";
      };
      plex = {
        enable = true;
        domain = "plex.joshvanl.dev";
      };
    };
  };
}
