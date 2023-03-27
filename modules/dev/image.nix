{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.dev.image;

in {
  options.me.dev.image = {
    enable = mkEnableOption "dev.image";
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.me.base.username}.home.packages = with pkgs; [
      imagemagick
      imv
      gthumb
    ];
  };
}
