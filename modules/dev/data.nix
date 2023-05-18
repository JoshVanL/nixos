{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.dev.data;

in {
  options.me.dev.data = {
    enable = mkEnableOption "dev.data";
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.me.base.username}.home.packages = with pkgs; [
      calc
      zip
      unzip
      postgresql
      jq
    ];
  };
}
