{ lib, pkgs, config, ... }:
with lib;

let
  cfg = config.me.roles;

in {
  config = mkIf (elem "nixsub" cfg.assume) {
    me.base.nix = {
      extraSubstituters = [
        "http://nixcache.joshvanl.dev/"
        "http://machinecache.joshvanl.dev/"
      ];
      trusted-public-keys = config.me.security.joshvanl.nixPublicKeys;
    };
  };
}
