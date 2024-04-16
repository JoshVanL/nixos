{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.data.img;

in {
  options.me.data.img = {
    enable = mkEnableOption "img";
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.me.username} = {
      home = {
        packages = with pkgs; [
          darktable
        ];
      };
    };
  };
}
