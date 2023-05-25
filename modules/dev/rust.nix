{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.dev.rust;

in {
  options.me.dev.rust = {
    enable = mkEnableOption "dev.rust";
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.me.username} = {
      home.packages = with pkgs; [
        rustc
      ];
    };
  };
}
