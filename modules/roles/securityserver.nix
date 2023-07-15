{ lib, pkgs, config, ... }:
with lib;

let
  cfg = config.me.roles;

in {
  config = mkIf (elem "securityserver" cfg.assume) {
    me.security = {
      bitwarden.server = {
        enable = true;
        domain = "bitwarden.joshvanl.dev";
      };
    };
  };
}
