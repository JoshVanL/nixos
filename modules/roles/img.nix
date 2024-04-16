{ lib, pkgs, config, ... }:
with lib;

let
  cfg = config.me.roles;

in {
  config = mkIf (elem "img" cfg.assume) {
    me.data.img = {
      enable = true;
    };
  };
}
