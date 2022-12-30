{ config, lib, pkgs, ... }:

{
  xdg.configFile."i3/config".text = builtins.readFile ./i3.config;

  home.packages = with pkgs; [
    xclip
  ];

  programs.i3status = {
    enable = true;

    general = {
      colors = true;
      color_good = "#8C9440";
      color_bad = "#A54242";
      color_degraded = "#DE935F";
    };

    modules = {
      ipv6.enable = false;
      "wireless _first_".enable = false;
      "battery all".enable = false;
    };
  };
}
