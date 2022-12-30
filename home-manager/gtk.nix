{ config, lib, pkgs, ... }:

{
  home.packages = [ pkgs.dconf ];
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
}
