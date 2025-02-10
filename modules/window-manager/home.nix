{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.window-manager;

in {
  config = mkIf config.me.window-manager.enable {
    systemd.tmpfiles.rules = [];

    home-manager.users.${config.me.username} = {
      home.packages = with pkgs; [
      ];
    };
  };
}
