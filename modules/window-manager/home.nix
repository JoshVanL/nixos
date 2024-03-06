{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.window-manager;

in {
  config = mkIf config.me.window-manager.enable {
    systemd.tmpfiles.rules = [
      "d /persist/home/.config/binday 0700 ${config.me.username} wheel - -"
      "L+ /home/${config.me.username}/.config/binday - - - - /persist/home/.config/binday"
    ];

    home-manager.users.${config.me.username} = {
      home.packages = with pkgs; [
        binday
      ];
    };
  };
}
