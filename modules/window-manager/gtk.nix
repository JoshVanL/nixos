{ lib, pkgs, config, ... }:
with lib;
{
  config = mkIf config.me.window-manager.enable {
    home-manager.users.${config.me.base.username} = {
      home.packages = with pkgs; [
        dconf
      ];
      gtk = {
        enable = true;
        font = {
          name = "San Francisco Display Regular";
        };
        theme = {
          name = "Arc-Dark";
          package = pkgs.arc-theme;
        };
      };
    };
  };
}
