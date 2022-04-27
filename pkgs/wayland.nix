{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    wl-clipboard
  ];

  programs.sway = {
    enable = true;
    wrapperFeatures = {
      gtk = true;
    };
  };
}
