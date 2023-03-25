{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.dev.c;

in {
  options.me.dev.c = {
    enable = mkEnableOption "dev.c";
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.me.username}.home.packages = with pkgs; [
      gcc
    ];
  };
}
