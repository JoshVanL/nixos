{ lib, pkgs, config, ... }:
with lib;

let
  cfg = config.me.roles;

in {
  options.me.roles.media = {
    transmit = mkEnableOption "roles.media.transmit";
  };

  config = mkIf (elem "mediaserver" cfg.assume) {
    networking.nat = mkIf cfg.media.transmit {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "wg0";
    };

    me.data.media = {
      transmission.enable = cfg.media.transmit;
      radarr = {
        enable = cfg.media.transmit;
        domain = "dish.joshvanl.dev";
      };
      sonarr = {
        enable = cfg.media.transmit;
        domain = "sat.joshvanl.dev";
      };
      jackett = {
        enable = cfg.media.transmit;
        domain = "hoodie.joshvanl.dev";
      };
      plex = {
        enable = true;
        domain = "plex.joshvanl.dev";
      };
    };
  };
}
